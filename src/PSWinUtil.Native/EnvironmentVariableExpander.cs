using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PSWinUtil
{
    public static class EnvironmentVariableExpander
    {
        private const uint TokenQuery = 0x0008;

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetCurrentProcess();

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(
            IntPtr processHandle,
            uint desiredAccess,
            out IntPtr tokenHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool CloseHandle(IntPtr handle);

        [DllImport("userenv.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern uint ExpandEnvironmentStringsForUser(
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

            var token = IntPtr.Zero;
            try
            {
                if (string.Equals(scope, "User", StringComparison.OrdinalIgnoreCase))
                {
                    if (!OpenProcessToken(GetCurrentProcess(), TokenQuery, out token))
                    {
                        return value;
                    }
                }

                return ExpandForUser(token, value);
            }
            catch (DllNotFoundException)
            {
                return value;
            }
            catch (EntryPointNotFoundException)
            {
                return value;
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
            var length = 256u;
            while (true)
            {
                var builder = new StringBuilder((int)length);
                var requiredLength = ExpandEnvironmentStringsForUser(
                    token,
                    value,
                    builder,
                    length);
                if (requiredLength == 0)
                {
                    return value;
                }
                if (requiredLength < length)
                {
                    return builder.ToString();
                }

                length = requiredLength + 1;
            }
        }
    }
}
