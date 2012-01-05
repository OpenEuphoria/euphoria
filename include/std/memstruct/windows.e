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
	object as PSTR,
	object as HMENU,
	unsigned short as ATOM,
	object as ULONG_PTR,
	object as LPVOID,
	object as LPBOOL,
	short as SHORT,
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

public memstruct OSVERSIONINFOEX
	DWORD dwOSVersionInfoSize
	DWORD dwMajorVersion
	DWORD dwMinorVersion
	DWORD dwBuildNumber
	DWORD dwPlatformId
	TCHAR szCSDVersion[128]
	WORD  wServicePackMajor
	WORD  wServicePackMinor
	WORD  wSuiteMask
	BYTE  wProductType
	BYTE  wReserved
end memstruct

public memstruct INITCOMMONCONTROLSEX
	DWORD dwSize
	DWORD dwICC
end memstruct

public memstruct TOOLINFO
  UINT      cbSize
  UINT      uFlags
  HWND      hwnd
  UINT_PTR  uId
  RECT      rect
  HINSTANCE hinst
  LPTSTR    lpszText
-- #if (_WIN32_IE >= 0x0300)
  LPARAM    lParam
-- #endif 
-- #if (_WIN32_WINNT >= Ox0501)
  object lpReserved
-- #endif 
end memstruct

public memstruct WINDOWINFO
	DWORD cbSize
	RECT  rcWindow
	RECT  rcClient
	DWORD dwStyle
	DWORD dwExStyle
	DWORD dwWindowStatus
	UINT  cxWindowBorders
	UINT  cyWindowBorders
	ATOM  atomWindowType
	WORD  wCreatorVersion
end memstruct

public memstruct PARAFORMAT
	UINT  cbSize
	DWORD dwMask
	WORD  wNumbering
	WORD  wReserved
	LONG  dxStartIndent
	LONG  dxRightIndent
	LONG  dxOffset
	WORD  wAlignment
	SHORT cTabCount
	LONG  rgxTabs
end memstruct

public memstruct PANOSE
	BYTE bFamilyType
	BYTE bSerifStyle
	BYTE bWeight
	BYTE bProportion
	BYTE bContrast
	BYTE bStrokeVariation
	BYTE bArmStyle
	BYTE bLetterform
	BYTE bMidline
	BYTE bXHeight
end memstruct

public memstruct TEXTMETRIC
	LONG  tmHeight
	LONG  tmAscent
	LONG  tmDescent
	LONG  tmInternalLeading
	LONG  tmExternalLeading
	LONG  tmAveCharWidth
	LONG  tmMaxCharWidth
	LONG  tmWeight
	LONG  tmOverhang
	LONG  tmDigitizedAspectX
	LONG  tmDigitizedAspectY
	TCHAR tmFirstChar
	TCHAR tmLastChar
	TCHAR tmDefaultChar
	TCHAR tmBreakChar
	BYTE  tmItalic
	BYTE  tmUnderlined
	BYTE  tmStruckOut
	BYTE  tmPitchAndFamily
	BYTE  tmCharSet
end memstruct

public memstruct OUTLINETEXTMETRIC
	UINT       otmSize
	TEXTMETRIC otmTextMetrics
	BYTE       otmFiller
	PANOSE     otmPanoseNumber
	UINT       otmfsSelection
	UINT       otmfsType
	int        otmsCharSlopeRise
	int        otmsCharSlopeRun
	int        otmItalicAngle
	UINT       otmEMSquare
	int        otmAscent
	int        otmDescent
	UINT       otmLineGap
	UINT       otmsCapEmHeight
	UINT       otmsXHeight
	RECT       otmrcFontBox
	int        otmMacAscent
	int        otmMacDescent
	UINT       otmMacLineGap
	UINT       otmusMinimumPPEM
	POINT      otmptSubscriptSize
	POINT      otmptSubscriptOffset
	POINT      otmptSuperscriptSize
	POINT      otmptSuperscriptOffset
	UINT       otmsStrikeoutSize
	int        otmsStrikeoutPosition
	int        otmsUnderscoreSize
	int        otmsUnderscorePosition
	PSTR       otmpFamilyName
	PSTR       otmpFaceName
	PSTR       otmpStyleName
	PSTR       otmpFullName
end memstruct

public memstruct SIZE
	LONG cx
	LONG cy
end memstruct

public memstruct MENUITEMINFO
	UINT      cbSize
	UINT      fMask
	UINT      fType
	UINT      fState
	UINT      wID
	HMENU     hSubMenu
	HBITMAP   hbmpChecked
	HBITMAP   hbmpUnchecked
	ULONG_PTR dwItemData
	LPTSTR    dwTypeData
	UINT      cch
	HBITMAP   hbmpItem
end memstruct

public memstruct LVBKIMAGE
	ULONG   ulFlags
	HBITMAP hbm
	LPTSTR  pszImage
	UINT    cchImageMax
	int     xOffsetPercent
	int     yOffsetPercent
end memstruct

public memstruct TCITEM
	UINT   mask
-- 	#if (_WIN32_IE >= 0x0300)
	DWORD  dwState
	DWORD  dwStateMask
-- 	#else 
-- 	UINT   lpReserved1
-- 	UINT   lpReserved2
-- 	#endif 
	LPTSTR pszText
	int    cchTextMax
	int    iImage
	LPARAM lParam
end memstruct

public memstruct BITMAP
	int bmType
	int bmWidth
	int bmHeight
	int bmWidthBytes
	BYTE bmPlanes
	BYTE bmBitsPixel
	LPVOID bmBits
end memstruct

public memstruct BITMAPINFOHEADER
	DWORD biSize
	LONG  biWidth
	LONG  biHeight
	WORD  biPlanes
	WORD  biBitCount
	DWORD biCompression
	DWORD biSizeImage
	LONG  biXPelsPerMeter
	LONG  biYPelsPerMeter
	DWORD biClrUsed
	DWORD biClrImportant
end memstruct


public memstruct DRAWTEXTPARAMS
	UINT cbSize
	int  iTabLength
	int  iLeftMargin
	int  iRightMargin
	UINT uiLengthDrawn
end memstruct

public memstruct GETTEXTEX
	DWORD  cb
	DWORD  flags
	UINT   codepage
	LPCSTR lpDefaultChar
	LPBOOL lpUsedDefChar
end memstruct

public memstruct SYSTEMTIME
	WORD wYear
	WORD wMonth
	WORD wDayOfWeek
	WORD wDay
	WORD wHour
	WORD wMinute
	WORD wSecond
	WORD wMilliseconds
end memstruct

public memstruct TEXTRANGE
	CHARRANGE chrg
	LPSTR     lpstrText
end memstruct

public memstruct SCROLLINFO
	UINT cbSize
	UINT fMask
	int  nMin
	int  nMax
	UINT nPage
	int  nPos
	int  nTrackPos
end memstruct

public memstruct TTHITTESTINFO
	HWND     hwnd
	POINT    pt
	TOOLINFO ti
end memstruct

public memstruct NMTTDISPINFO
	NMHDR     hdr
	LPTSTR    lpszText
	TCHAR     szText[80]
	HINSTANCE hinst
	UINT      uFlags
-- 	#if (_WIN32_IE >= 0x0300)
	LPARAM    lParam
-- #endif 
end memstruct

public memstruct LVFINDINFO
	UINT    flags
	LPCTSTR psz
	LPARAM  lParam
	POINT   pt
	UINT    vkDirection
end memstruct

public memstruct CHARFORMAT
	UINT     cbSize
	DWORD    dwMask
	DWORD    dwEffects
	LONG     yHeight
	LONG     yOffset
	COLORREF crTextColor
	BYTE     bCharSet
	BYTE     bPitchAndFamily
	TCHAR    szFaceName[LF_FACESIZE]
end memstruct

public memstruct RGBQUAD
	BYTE rgbBlue
	BYTE rgbGreen
	BYTE rgbRed
	BYTE rgbReserved
end memstruct

public memstruct BITMAPINFO
	BITMAPINFOHEADER bmiHeader
	RGBQUAD bmiColors[1]
end memstruct
