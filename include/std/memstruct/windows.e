--****
-- == Common Windows Memstructs
--
-- <<LEVELTOC level=2 depth=5>>
--

--****
-- === Windows Type constants for structs

public memtype
	char as BYTE,
	int as BOOL,
	int as INT,
	unsigned int as UINT,
	long as LONG,
	unsigned long as ULONG,
	double as DOUBLE,
	short as WORD,
	long as DWORD,
	object as HANDLE,
	object as HWND,
	object as LPSTR,
	object as LPTSTR,
	object as WNDPROC,
	object as WPARAM,
	object as LPARAM,
	object as HINSTANCE,
	object as LPCSTR,
	object as LPCTSTR,
	object as LPOFNHOOKPROC,
	object as BFFCALLBACK,
	unsigned short as USHORT,
	object as LPCCHOOKPROC,
	long as COLORREF,
	object as INT_PTR,
	object as UINT_PTR,
	$
	
--****
-- === Windows structures

public memstruct WNDCLASSEX
	UINT cbSize
	UINT style
	WNDPROC lpfnWndProc  	--WNDPROC
	INT cbClsExtra
	INT cbWndExtra
	HANDLE hInstance  	--HINSTANCE
	HANDLE hIcon   		--HICON
	HANDLE hCursor  	--HCURSOR
	HANDLE hbrBackground 	--HBRUSH
	LPSTR lpszMenuName  	--LPCSTR
	LPSTR lpszClassName	--LPCSTR
	HANDLE hIconSm		--HICON
end memstruct

public memstruct POINT
	LONG x
	LONG y
end memstruct

public memstruct RECT
	LONG left
	LONG top
	LONG right
	LONG bottom
end memstruct

public memstruct PAINTSTRUCT
	HANDLE hdc		--HDC
	BOOL fErase
	RECT rcPaint		--RECT
	BOOL fRestore
	BOOL fIncUpdate
	BYTE rgbReserved[32]	--BYTE,32
end memstruct

public memstruct MSG
	HWND hwnd
	UINT message
	WPARAM wParam
	LPARAM lParam
	DWORD time
	POINT pt
end memstruct

public memstruct NMHDR
	HWND hwndFrom
	UINT_PTR idFrom
	UINT code
end memstruct

public memstruct LVCOLUMN
	UINT mask
	int fmt
	int cx
	LPTSTR pszText
	int cchTextMax
	int iSubItem
	int iImage
	int iOrder
	int cxMin
	int cxDefault
	int cxIdeal
end memstruct

public memstruct LVITEM
	UINT mask
	int    iItem
	int    iSubItem
	UINT   state
	UINT   stateMask
	LPTSTR pszText
	int    cchTextMax
	int    iImage
	object lParam
-- 	#if (_WIN32_IE >= 0x0300)
	int    iIndent
-- 	#endif 
-- 	#if (_WIN32_WINNT >= 0x0501)
	int    iGroupId
	UINT   cColumns
	UINT   puColumns
-- 	#endif 
-- 	#if (_WIN32_WINNT >= 0x0600)
	int    piColFmt
	int    iGroup
end memstruct

public memstruct LV_DISPINFO
	NMHDR hdr
	LVITEM item
end memstruct

public memstruct OPENFILENAME
  DWORD         lStructSize
  HWND          hwndOwner
  HINSTANCE     hInstance
  LPCTSTR       lpstrFilter
  LPTSTR        lpstrCustomFilter
  DWORD         nMaxCustFilter
  DWORD         nFilterIndex
  LPTSTR        lpstrFile
  DWORD         nMaxFile
  LPTSTR        lpstrFileTitle
  DWORD         nMaxFileTitle
  LPCTSTR       lpstrInitialDir
  LPCTSTR       lpstrTitle
  DWORD         Flags
  WORD          nFileOffset
  WORD          nFileExtension
  LPCTSTR       lpstrDefExt
  LPARAM        lCustData
  LPOFNHOOKPROC lpfnHook
  LPCTSTR       lpTemplateName
-- #if (_WIN32_WINNT >= 0x0500)
  object        pvReserved
  DWORD         dwReserved
  DWORD         FlagsEx
-- #endif 
end memstruct

public memstruct SHITEMID
	USHORT cb
	pointer BYTE abID
end memstruct

public memstruct BROWSEINFO
	HWND              hwndOwner
	pointer SHITEMID  pidlRoot
	LPTSTR            pszDisplayName
	LPCTSTR           lpszTitle
	UINT              ulFlags
	BFFCALLBACK       lpfn
	LPARAM            lParam
	int               iImage
end memstruct

public memstruct CHOOSECOLOR
	DWORD        lStructSize
	HWND         hwndOwner
	HWND         hInstance
	COLORREF     rgbResult
	pointer COLORREF     lpCustColors
	DWORD        Flags
	LPARAM       lCustData
	LPCCHOOKPROC lpfnHook
	LPCTSTR      lpTemplateName
end memstruct

public memstruct COMBOBOXEXITEM
	UINT    mask
	INT_PTR iItem
	LPTSTR  pszText
	int     cchTextMax
	int     iImage
	int     iSelectedImage
	int     iOverlay
	int     iIndent
	LPARAM  lParam
end memstruct

public memstruct NMLISTVIEW
	NMHDR  hdr
	int    iItem
	int    iSubItem
	UINT   uNewState
	UINT   uOldState
	UINT   uChanged
	POINT  ptAction
	LPARAM lParam
end memstruct
