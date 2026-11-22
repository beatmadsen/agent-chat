require 'sqlite3'

# sqlite3 looks up the UTF-16 encodings on its first query that binds a
# string, and Ruby loads them on demand. A Ctrl-C that lands during that load,
# inside the extension's C code, crashes Ruby with a [BUG] report instead of
# raising Interrupt. Loading them here, before any query, closes that window.
require 'enc/utf_16le'
require 'enc/utf_16be'
