# Сборка

## Windows (с WinDivert — рекомендуется)

### 1. Скачай WinDivert

Скачай последний релиз с https://github.com/basil00/Divert/releases  
Распакуй так чтобы получилась структура:

```
dpibypass/
  vendor/
    windivert/
      include/
        windivert.h
      lib/
        x64/
          WinDivert.dll
          WinDivert.lib
          WinDivert.sys
        x86/
          WinDivert.dll
          WinDivert.lib
          WinDivert.sys
```

### 2. Собери

Нужен: CMake, MinGW или MSVC

```bash
mkdir build && cd build
cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

Бинарник появится в `build/dpibypass.exe`  
Рядом автоматически скопируются `WinDivert.dll` и `WinDivert.sys`.

### 3. Запусти GUI от администратора

```bash
python windows/gui.py
```

Выбери режим **WinDivert** и нажми **Авто-подбор и запуск**.  
Браузер настраивать не нужно — работает системно для всех приложений.

---

## Windows (без WinDivert — SOCKS5 режим)

Если не хочешь скачивать WinDivert, собери без него:

```bash
mkdir build && cd build
cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

CMake предупредит что WinDivert не найден и соберёт без него.  
В GUI выбери режим **SOCKS5** и настрой прокси в браузере: `127.0.0.1:1080`.

---

## Linux / macOS

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make
./dpibypass -t -s 1
```

## Параметры командной строки

```
dpibypass [опции]
  -i <ip>     IP для прослушивания (по умолчанию 127.0.0.1)
  -p <port>   Порт (по умолчанию 1080)
  -s <pos>    Позиция разбивки пакета
  -d          Disorder режим
  -f <ttl>    TTL для fake-пакета
  -t          Разбивать TLS record по SNI
  -o          OOB байт между частями
  -w          WinDivert режим (системный, требует администратора)
  -U <host>   Upstream SOCKS5 прокси
  -P <port>   Порт upstream прокси
```
