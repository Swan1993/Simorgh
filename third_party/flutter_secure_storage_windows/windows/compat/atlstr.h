#ifndef SIMORGH_ATLSTR_COMPAT_H_
#define SIMORGH_ATLSTR_COMPAT_H_

#include <windows.h>

#include <string>

// The upstream plugin only uses ATL's narrow/wide conversion wrappers. Keep
// this small compatibility layer local to the vendored plugin so the Windows
// build does not require the optional ATL headers.
class CA2W {
 public:
  explicit CA2W(const char* source) : value_(ToWide(source)), m_psz(value_.c_str()) {}

  const wchar_t* m_psz;

 private:
  static std::wstring ToWide(const char* source) {
    if (source == nullptr || *source == '\0') {
      return {};
    }
    const int size = MultiByteToWideChar(CP_ACP, 0, source, -1, nullptr, 0);
    if (size <= 1) {
      return {};
    }
    std::wstring result(size, L'\0');
    MultiByteToWideChar(CP_ACP, 0, source, -1, result.data(), size);
    result.resize(size - 1);
    return result;
  }

  std::wstring value_;
};

class CW2A {
 public:
  explicit CW2A(const wchar_t* source) : value_(ToNarrow(source)) {}

  operator const char*() const { return value_.c_str(); }

 private:
  static std::string ToNarrow(const wchar_t* source) {
    if (source == nullptr || *source == L'\0') {
      return {};
    }
    const int size = WideCharToMultiByte(
        CP_ACP, 0, source, -1, nullptr, 0, nullptr, nullptr);
    if (size <= 1) {
      return {};
    }
    std::string result(size, '\0');
    WideCharToMultiByte(
        CP_ACP, 0, source, -1, result.data(), size, nullptr, nullptr);
    result.resize(size - 1);
    return result;
  }

  std::string value_;
};

#endif  // SIMORGH_ATLSTR_COMPAT_H_
