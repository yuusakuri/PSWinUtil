namespace PSWinUtil
{
    public sealed class ExternalCommandResult
    {
        public bool Succeeded { get; }

        public int ExitCode { get; }

        public string StandardOutput { get; }

        public string StandardError { get; }

        public ExternalCommandResult(bool succeeded, int exitCode, string standardOutput, string standardError)
        {
            Succeeded = succeeded;
            ExitCode = exitCode;
            StandardOutput = standardOutput;
            StandardError = standardError;
        }
    }
}
