# Assets Images

## Logo ufficiale

Copia qui il file `logo.jpeg` (Icon-512 fornito).

Path atteso: `assets/images/logo.jpeg`

Tutte le schermate usano:
```dart
Image.asset('assets/images/logo.jpeg', ...)
```
con un fallback automatico se il file non è presente.

**Dimensioni consigliate**: 512x512 px, formato JPEG o PNG.
