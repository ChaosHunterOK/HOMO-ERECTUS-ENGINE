package;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
</target>
')
@:headerCode('
#include <Windows.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>

static BOOL CALLBACK __WindowsData_EnumProc(HWND hwnd, LPARAM lParam)
{
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid == GetCurrentProcessId() && IsWindowVisible(hwnd) && GetWindow(hwnd, GW_OWNER) == NULL)
    {
        *((HWND*)lParam) = hwnd;
        return FALSE;
    }
    return TRUE;
}

static HWND __WindowsData_GetGameWindow()
{
    HWND result = NULL;
    EnumWindows(__WindowsData_EnumProc, (LPARAM)&result);
    if (result == NULL)
        result = GetActiveWindow();
    return result;
}
')
#elseif linux
@:headerCode("#include <stdio.h>")
#end
class WindowsData
{
	#if windows
	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);

		return (allocatedRAM / 1024);
	")
	#elseif linux
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

    	if(meminfo == NULL)
			return -1;

    	char line[256];
    	while(fgets(line, sizeof(line), meminfo))
    	{
        	int ram;
        	if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
        	{
            	fclose(meminfo);
            	return (ram / 1024);
        	}
    	}

    	fclose(meminfo);
    	return -1;
	')
	#end
	public static function obtainRAM()
	{
		return 0;
	}

	#if windows
	@:functionCode('
        int darkMode = mode;
        HWND window = __WindowsData_GetGameWindow();
        if (window == NULL) return;
        if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
            DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
        }
        UpdateWindow(window);
    ')
	@:noCompletion
	public static function _setWindowColorMode(mode:Int)
	{
	}

	public static function setWindowColorMode(mode:WindowColorMode)
	{
		var darkMode:Int = cast(mode, Int);

		if (darkMode > 1 || darkMode < 0)
		{
			trace("WindowColorMode Not Found...");

			return;
		}

		_setWindowColorMode(darkMode);
	}

	@:functionCode('
	HWND window = __WindowsData_GetGameWindow();
	if (window == NULL) return;
	SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
	')
	@:noCompletion
	public static function _setWindowLayered()
	{
	}

	@:functionCode('
        HWND window = __WindowsData_GetGameWindow();
        if (window == NULL) return alpha;

		float a = alpha;

		if (a > 1) {
			a = 1;
		}
		if (a < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(window, 0, (BYTE)(a * 255), LWA_ALPHA);

    ')
	/**
	 * Set Whole Window's Opacity
	 * ! MAKE SURE TO CALL CppAPI._setWindowLayered(); BEFORE RUNNING THIS
	 * @param alpha 
	 */
	public static function setWindowAlpha(alpha:Float)
	{
		return alpha;
	}
	#end
}

enum abstract WindowColorMode(Int)
{
	var DARK:WindowColorMode = 1;
	var LIGHT:WindowColorMode = 0;
}
