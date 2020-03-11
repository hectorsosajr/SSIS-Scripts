
    /// <summary>
    /// ScriptMain is the entry point class of the script.  Do not change the name, attributes,
    /// or parent of this class.
    /// </summary>
    [Microsoft.SqlServer.Dts.Tasks.ScriptTask.SSISScriptTaskEntryPointAttribute]
    public partial class ScriptMain : Microsoft.SqlServer.Dts.Tasks.ScriptTask.VSTARTScriptObjectModelBase
    {
        /// <summary>
        /// This method is called when this script task executes in the control flow.
        /// Before returning from this method, set the value of Dts.TaskResult to indicate success or failure.
        /// To open Help, press F1.
        /// </summary>
        public void Main()
        {
            bool failure = false;
            bool fireAgain = true;

            foreach (var connMgr in Dts.Connections)
            {
                Dts.Events.FireInformation(1, "", String.Format("ConnectionManager='{0}', ConnectionString='{1}'",connMgr.Name, connMgr.ConnectionString), "", 0, ref fireAgain);
                try
                {
                    connMgr.AcquireConnection(null);
                    Dts.Events.FireInformation(1, "", String.Format("Connection acquired successfully on '{0}'",connMgr.Name), "", 0, ref fireAgain);
                }
                catch (Exception ex)
                {
                    Dts.Events.FireError(-1, "", String.Format("Failed to acquire connection to '{0}'. Error Message='{1}'",connMgr.Name, ex.Message),"", 0);
                    failure = true;
                }
            }

            if (failure)
                Dts.TaskResult = (int)ScriptResults.Failure;
            else
                Dts.TaskResult = (int)ScriptResults.Success;
        }

        #region ScriptResults declaration
        /// <summary>
        /// This enum provides a convenient shorthand within the scope of this class for setting the
        /// result of the script.
        /// 
        /// This code was generated automatically.
        /// </summary>
        enum ScriptResults
        {
            Success = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Success,
            Failure = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Failure
        };
        #endregion
    }