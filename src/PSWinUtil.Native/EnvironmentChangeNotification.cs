using System;
using System.Runtime.InteropServices;

namespace PSWinUtil
{
    public static class EnvironmentChangeNotification
    {
        private static readonly IntPtr HwndBroadcast = new IntPtr(0xffff);
        private const uint WmSettingChange = 0x001a;
        private const uint SmtoAbortIfHung = 0x0002;
        // HWND_BROADCAST applies this timeout to each receiving window, not the entire call.
        private const uint ReceiverTimeoutMilliseconds = 100;

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr SendMessageTimeout(
            IntPtr hWnd,
            uint message,
            IntPtr wParam,
            string lParam,
            uint flags,
            uint timeout,
            out IntPtr result);

        public static bool Broadcast()
        {
            IntPtr result;
            return SendMessageTimeout(
                HwndBroadcast,
                WmSettingChange,
                IntPtr.Zero,
                "Environment",
                SmtoAbortIfHung,
                ReceiverTimeoutMilliseconds,
                out result) != IntPtr.Zero;
        }
    }
}
