using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace PSWinUtil
{
    public static class EnvironmentVariableExpander
    {
        private const uint TokenDuplicate = 0x0002;
        private const uint TokenImpersonate = 0x0004;
        private const uint TokenQuery = 0x0008;
        private const uint TokenAccess = TokenDuplicate | TokenImpersonate | TokenQuery;
        private const int ErrorInsufficientBuffer = 122;

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetCurrentProcess();

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(
            IntPtr processHandle,
            uint desiredAccess,
            out IntPtr tokenHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr handle);

        [DllImport("userenv.dll", EntryPoint = "ExpandEnvironmentStringsForUserW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool ExpandEnvironmentStringsForUser(
            IntPtr token,
            string source,
            StringBuilder destination,
            uint destinationLength);

        public static string Expand(string value, string scope)
        {
            if (value == null)
            {
                return null;
            }

            if (string.Equals(scope, "Process", StringComparison.OrdinalIgnoreCase))
            {
                return Environment.ExpandEnvironmentVariables(value);
            }
            if (!string.Equals(scope, "User", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(scope, "Machine", StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException("Scope must be Process, User, or Machine.", nameof(scope));
            }

            var token = IntPtr.Zero;
            try
            {
                if (string.Equals(scope, "User", StringComparison.OrdinalIgnoreCase))
                {
                    if (!OpenProcessToken(GetCurrentProcess(), TokenAccess, out token))
                    {
                        throw new Win32Exception(Marshal.GetLastWin32Error());
                    }
                }

                return ExpandForUser(token, value);
            }
            finally
            {
                if (token != IntPtr.Zero)
                {
                    CloseHandle(token);
                }
            }
        }

        private static string ExpandForUser(IntPtr token, string value)
        {
            var length = Math.Max(256, value.Length + 1);
            while (length <= 1048576)
            {
                var builder = new StringBuilder(length);
                if (ExpandEnvironmentStringsForUser(
                    token,
                    value,
                    builder,
                    (uint)length))
                {
                    return builder.ToString();
                }

                var error = Marshal.GetLastWin32Error();
                if (error != ErrorInsufficientBuffer)
                {
                    throw new Win32Exception(error);
                }
                length *= 2;
            }

            throw new ArgumentException("Expanded environment value is too long.", nameof(value));
        }
    }
}
