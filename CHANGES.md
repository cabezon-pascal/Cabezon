# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

(This file has been named `CHANGES.md`, because `CHANGELOG.md` exceeds the DOS
8.3 limit.)

## [Unreleased]
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

Note: Anything below is a translation of the now-deleted file `src/CABEZON.LOG`
from Japanese to English using [Google Translate](https://translate.google.com/)
and [DeepL Translate](https://www.deepl.com/). Improvements are welcome.

## [0.08] - 1993-01-04
### Added
- Added support for `huge` arrays.
- Japanese can be used for an identifier. However, since the Japanese
  identifier is not converted to alphanumeric characters and is used in the
  assembly code as it is, programming using Japanese is not possible unless
  an assembler that can understand the Japanese identifier is used.
- In the built-in function `paramStr`, the execution path is now returned
  when the argument `0` is given.
- The built-in functions `bitshift`, `cpos`, `min`, `max`, and the built-in
  procedures `gettime` and `getdate` were added. The procedures `gettime` and
  `getdate` were created by Mr. maquiwo, and we added them to the standard
  library with his permission. I would like to express my gratitude to him.

### Changed
- Improved the code of the `with` statement.
- Error messages are now separated from the compiler and placed in a separate
  file (`cabezon.err`).
- Declarations of built-in functions and procedures are now separated from
  the compiler and placed in a separate file (`cabezon.ini`).

### Fixed
- In a `string` type definition, error checking is now performed when the
  value exceeds 32K bytes.

## [0.07] - 1992-06-10
### Added
- Added support for convolution of logical constant expressions.

### Changed
- Improved the argument code so that variables can be pushed directly.
- The code of the `for` statement has been improved so that it can execute a
  constant loop efficiently.

### Fixed
- Fixed a bug when using comparison operators in assignment statements.
- Fixed a bug in the case where a procedure declared in the `interface`
  clause is declared as `external`.
- The global `goto` statement can now be used. This feature was originally
  supported, but a bug in Ver0.06 prevented its use.
- Fixed some bugs in the document. The text formatter was changed to FPLF.

## [0.06] - 1991-11-19
### Added
- Added inline expansion of binary search as an implementation of `case`
  statement. This method was taught by suto.
- Added a range check option for partial range type.
- Added support for R86, the assembler included with LSI C-86.

### Changed
- Improved the code generator of the expression.

## [0.05] - 1991-03-21
### Added
- Added a function for convolution of constant arithmetic operations, which
  eliminates the need for indexing calculations in array references such as
  `a[3, 4]`.
- Added code to the startup routine to release the heap area at startup.
  Previously, the `/cp:1` option of link was used, now eliminating the
  drawback of not being able to use the heap with linkers other than MS-LINK.

### Changed
- Improved the code generator.
- Parts of the library were rewritten in assembler.

### Fixed
- Fixed a bug that the symbol indicating the return value of a function was
  not released when defining a structural type function.

## [0.04] - 1991-03-17
### Added
- Implemented the string concatenation operator `+` and the embedding
  procedure.
- Implemented a built-in function that acquires run-time parameters.

### Changed
- The description language was changed from Turbo Pascal Ver5.5 to Cabezon
  itself.

## [0.03] - 1991-02-20
### Added
- Implemented procedures `new` / `dispose`
- Implemented the following procedures to support `text` type
  - `assign`, `reset`, `rewrite`, `close`
  - `read`, `readln`, `write`, `writeln`
  - `eof`
- The compiler driver has been modified to delete assembly language programs
  after compiling and assembling. However, in the case of assemble only,
  it is not deleted.

### Changed
- Improved the display method of run-time errors. Changed to display the
  error code and error address.

### Fixed
- Fixed a bug in the `write` procedure that the negative value of an integer
  value is not output if the width is not specified.
- Fixed that `readln` with no argument was an error.
- Corrected an error in the handling of `label` symbols. It was reported that
  they had not been removed from the hash table.

## [0.02] - 1990-10-28
### Added
- Implemented `case` statement
- Implemented `with` statement
- Implemented `goto` statement
  - A name can be used for the `goto` label (ex. `goto exitMainLoop;`)
  - You can use `goto` to exit a procedure.
- Implemented `for every` statement

### Fixed
- Fixed a bug in the `for` statement that it did not cause an error even when
  the type of the expression was different from the control variable.

## [0.01] - 1990-08-22
### Added
- Initial version release
