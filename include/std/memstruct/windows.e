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
	char as TCHAR,
	object as HICON,
	object as HTREEITEM,
	object as LPFRHOOKPROC,
	object as EDITSTREAMCALLBACK,
	object as DWORD_PTR,
	object as HGLOBAL,
	object as LPPAGEPAINTHOOK,
	object as LPPAGESETUPHOOK,
	object as LPPRINTHOOKPROC,
	object as LPSETUPHOOKPROC,
	object as HDC,
	object as HBITMAP,
	object as LPLOGFONT,
	object as LPCFHOOKPROC,
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

public memtype POINT as POINTL

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

public memstruct SHFILEINFO
  HICON hIcon
  int   iIcon
  DWORD dwAttributes
  TCHAR szDisplayName[260]
  TCHAR szTypeName[80]
end memstruct

public memstruct TVITEM
	UINT      mask
	HTREEITEM hItem
	UINT      state
	UINT      stateMask
	LPTSTR    pszText
	int       cchTextMax
	int       iImage
	int       iSelectedImage
	int       cChildren
	LPARAM    lParam
end memstruct

public memstruct TVITEMEX
	UINT      mask
	HTREEITEM hItem
	UINT      state
	UINT      stateMask
	LPTSTR    pszText
	int       cchTextMax
	int       iImage
	int       iSelectedImage
	int       cChildren
	LPARAM    lParam
	int       iIntegral
-- 	#if (_WIN32_IE >= 0x0600)
	UINT      uStateEx
	HWND      hwnd
	int       iExpandedImage
-- -- 	#endif 
-- -- 	#if (NTDDI_VERSION >= NTDDI_WIN7)
	int       iReserved
-- 	#endif 
end memstruct

public memunion TVINSERTUNION
	TVITEMEX itemex
	TVITEM   item
end memunion

public memstruct TVINSERTSTRUCT
	HTREEITEM hParent
	HTREEITEM hInsertAfter
-- 	#if (_WIN32_IE >= 0x0400)
	TVINSERTUNION u
end memstruct

public memstruct NMTVDISPINFO
	NMHDR hdr
	TVITEM item
end memstruct

public memstruct NMTREEVIEW
	NMHDR  hdr
	UINT   action
	TVITEM itemOld
	TVITEM itemNew
	POINT  ptDrag
end memstruct

public memstruct TVHITTESTINFO
	POINT     pt
	UINT      flags
	HTREEITEM hItem
end memstruct

public memstruct NMCBEENDEDIT
	NMHDR hdr
	BOOL  fChanged
	int   iNewSelection
	TCHAR szText
	int   iWhy
end memstruct

public memstruct NMUPDOWN
	NMHDR hdr
	int   iPos
	int   iDelta
end memstruct

public memstruct FINDREPLACE
	DWORD        lStructSize
	HWND         hwndOwner
	HINSTANCE    hInstance
	DWORD        Flags
	LPTSTR       lpstrFindWhat
	LPTSTR       lpstrReplaceWith
	WORD         wFindWhatLen
	WORD         wReplaceWithLen
	LPARAM       lCustData
	LPFRHOOKPROC lpfnHook
	LPCTSTR      lpTemplateName
end memstruct


public memstruct LVHITTESTINFO
	POINT pt
	UINT  flags
	int   iItem
	int   iSubItem
	int   iGroup
end memstruct

-- richedit structs are aligned on 4 byte boundaries
public memstruct EDITSTREAM with pack 4
	DWORD_PTR          dwCookie
	DWORD              dwError
	EDITSTREAMCALLBACK pfnCallback
end memstruct

public memstruct PAGESETUPDLG
	DWORD           lStructSize
	HWND            hwndOwner
	HGLOBAL         hDevMode
	HGLOBAL         hDevNames
	DWORD           Flags
	POINT           ptPaperSize
	RECT            rtMinMargin
	RECT            rtMargin
	HINSTANCE       hInstance
	LPARAM          lCustData
	LPPAGESETUPHOOK lpfnPageSetupHook
	LPPAGEPAINTHOOK lpfnPagePaintHook
	LPCTSTR         lpPageSetupTemplateName
	HGLOBAL         hPageSetupTemplate
end memstruct

-- Stand in for anonymous struct in Windows headers
public memstruct DEVMODE_PAPER
	short dmOrientation
	short dmPaperSize
	short dmPaperLength
	short dmPaperWidth
	short dmScale
	short dmCopies
	short dmDefaultSource
	short dmPrintQuality
end memstruct

-- Stand in for anonymous struct in Windows headers
public memstruct DEVMODE_DISPLAY
	POINTL dmPosition
	DWORD  dmDisplayOrientation
	DWORD  dmDisplayFixedOutput
end memstruct

-- Stand in for an anonymous union in Windows headers.
public memunion DEVMODE_PAPER_VS_DISPLAY
	DEVMODE_PAPER paper
	DEVMODE_DISPLAY display
end memunion

-- Stand in for anonymous union in Windows headers
public memunion DEVMODE_FLAGS_VS_NUP
	DWORD dmDisplayFlags
	DWORD dmNup
end memunion

public constant CCHDEVICENAME = 32
public constant CCHFORMNAME   = 32

public memstruct DEVMODE
	TCHAR dmDeviceName[CCHDEVICENAME]
	WORD  dmSpecVersion
	WORD  dmDriverVersion
	WORD  dmSize
	WORD  dmDriverExtra
	DWORD dmFields
	
	-- pd is an anonymous union in Windows headers
	DEVMODE_PAPER_VS_DISPLAY pd
	short dmColor
	short dmDuplex
	short dmYResolution
	short dmTTOption
	short dmCollate
	TCHAR dmFormName[CCHFORMNAME]
	WORD  dmLogPixels
	DWORD dmBitsPerPel
	DWORD dmPelsWidth
	DWORD dmPelsHeight
	
	-- fn is an anonymous union in Windows headers
	DEVMODE_FLAGS_VS_NUP fn
	DWORD dmDisplayFrequency
	-- #if (WINVER >= 0x0400)
	DWORD dmICMMethod
	DWORD dmICMIntent
	DWORD dmMediaType
	DWORD dmDitherType
	DWORD dmReserved1
	DWORD dmReserved2
	-- #if (WINVER >= 0x0500) || (_WIN32_WINNT >= 0x0400)
	DWORD dmPanningWidth
	DWORD dmPanningHeight
	-- #endif 
	-- #endif 
end memstruct

public memstruct DOCINFO
	int     cbSize
	LPCTSTR lpszDocName
	LPCTSTR lpszOutput
	LPCTSTR lpszDatatype
	DWORD   fwType
end memstruct

public memstruct PRINTDLG
	DWORD           lStructSize
	HWND            hwndOwner
	HGLOBAL         hDevMode
	HGLOBAL         hDevNames
	HDC             hDC
	DWORD           Flags
	WORD            nFromPage
	WORD            nToPage
	WORD            nMinPage
	WORD            nMaxPage
	WORD            nCopies
	HINSTANCE       hInstance
	LPARAM          lCustData
	LPPRINTHOOKPROC lpfnPrintHook
	LPSETUPHOOKPROC lpfnSetupHook
	LPCTSTR         lpPrintTemplateName
	LPCTSTR         lpSetupTemplateName
	HGLOBAL         hPrintTemplate
	HGLOBAL         hSetupTemplate
end memstruct

public memstruct CHARRANGE
	LONG cpMin
	LONG cpMax
end memstruct

public memstruct FORMATRANGE
	HDC       hdc
	HDC       hdcTarget
	RECT      rc
	RECT      rcPage
	CHARRANGE chrg
end memstruct

public memstruct REBARBANDINFO
	UINT     cbSize
	UINT     fMask
	UINT     fStyle
	COLORREF clrFore
	COLORREF clrBack
	LPTSTR   lpText
	UINT     cch
	int      iImage
	HWND     hwndChild
	UINT     cxMinChild
	UINT     cyMinChild
	UINT     cx
	HBITMAP  hbmBack
	UINT     wID
-- 	#if (_WIN32_IE >= 0x0400)
	UINT     cyChild
	UINT     cyMaxChild
	UINT     cyIntegral
	UINT     cxIdeal
	LPARAM   lParam
	UINT     cxHeader
-- 	#endif 
-- 	#if (_WIN32_WINNT >= 0x0600)
	RECT     rcChevronLocation
	UINT     uChevronState
-- 	#endif 
end memstruct

public memstruct TBBUTTON
	int       iBitmap
	int       idCommand
	BYTE      fsState
	BYTE      fsStyle
-- #ifdef _WIN64
--   BYTE      bReserved[6]
-- #else 
-- #if defined(_WIN32)
--   BYTE      bReserved[2]
-- #endif 
-- #endif 
	DWORD_PTR dwData
	INT_PTR   iString
end memstruct

public constant LF_FACESIZE = 32
public memstruct LOGFONT
	LONG  lfHeight
	LONG  lfWidth
	LONG  lfEscapement
	LONG  lfOrientation
	LONG  lfWeight
	BYTE  lfItalic
	BYTE  lfUnderline
	BYTE  lfStrikeOut
	BYTE  lfCharSet
	BYTE  lfOutPrecision
	BYTE  lfClipPrecision
	BYTE  lfQuality
	BYTE  lfPitchAndFamily
	TCHAR lfFaceName[LF_FACESIZE]
end memstruct

public memstruct CHOOSEFONT
	DWORD        lStructSize
	HWND         hwndOwner
	HDC          hDC
	pointer LOGFONT    lpLogFont
	INT          iPointSize
	DWORD        Flags
	COLORREF     rgbColors
	LPARAM       lCustData
	LPCFHOOKPROC lpfnHook
	LPCTSTR      lpTemplateName
	HINSTANCE    hInstance
	LPTSTR       lpszStyle
	WORD         nFontType
	INT          nSizeMin
	INT          nSizeMax
end memstruct

public memstruct FINDTEXTEX
	CHARRANGE chrg
	LPCTSTR   lpstrText
	CHARRANGE chrgText
end memstruct
