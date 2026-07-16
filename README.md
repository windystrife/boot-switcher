# 🔁 boot-switcher

Tiny one-click helpers to reboot a UEFI dual-boot PC into the OS you want.

Each OS gets **two** launchers:

* **Reboot to Windows** — make the next boot go into Windows
* **Reboot to Linux** — make the next boot go into Linux

Use the *other-OS* one to switch over, or the *same-OS* one to simply restart without changing which OS you land in (handy when the machine's default boot order points at the other one).

All of them set the UEFI firmware's **one-time** boot target and then reboot. Your permanent boot order is never changed — only the *next* boot is redirected, so everything goes back to normal afterwards.

> 🇻🇳 **Tiếng Việt bên dưới** — [nhảy tới](#-tiếng-việt)

---

## How it works

* **Linux** uses `efibootmgr -n <entry>` to set the `BootNext` UEFI variable to the *Windows Boot Manager* entry.
* **Windows** uses `bcdedit /set {fwbootmgr} bootsequence <guid>` to set a one-time boot into the *Ubuntu* firmware entry.

Both are the standard, reversible UEFI mechanisms — no partition or bootloader is modified.

### Portable — works on any PC

Nothing is hard-coded (no fixed disk or boot-entry number). The target entry is **auto-detected at run time**:

* **Windows** is found by the universal `BOOTMGFW.EFI` boot path — reliable on every Windows install.
* **Linux** is found by its firmware entry name (`ubuntu`, `debian`, `fedora`, `arch`, `mint`, …) or by a GRUB/shim boot path (`grubx64.efi` / `shimx64.efi`).

If auto-detection picks the wrong entry (or your distro isn't recognized), force it:

```sh
# Linux → Windows
reboot-to-windows.sh "Windows"      # or a boot-entry number like 0006
```
```powershell
# Windows → Linux
reboot-to-linux.ps1 -Match fedora   # any name substring, or a {GUID}
```

## Requirements

* A **UEFI** system with both OSes installed (not legacy BIOS).
* **Linux:** `efibootmgr` (`sudo apt install efibootmgr`) and permission to reboot.
* **Windows:** the launcher self-elevates to Administrator.
* If **Secure Boot** blocks changing boot variables, do it from your firmware setup instead.

## Linux — install

```sh
cd linux
./install.sh
```

This puts **"Reboot to Windows"** and **"Reboot to Linux"** icons on your desktop and in the applications menu. Double-click one, confirm, and the PC reboots into that OS.

> Setting `BootNext` needs `sudo`. It runs without a prompt only if passwordless sudo is enabled for `efibootmgr`; otherwise launch it once from a terminal to type your password.

Run manually instead:

```sh
sudo ./reboot-to-windows.sh     # or ~/.local/bin/reboot-to-windows after install
```

## Windows — install

Copy the `windows/` folder somewhere handy. It contains two launchers:

* **`Reboot to Linux.cmd`** — reboot into Linux
* **`Reboot to Windows.cmd`** — restart back into Windows

Double-click one (it self-elevates, confirms, and reboots), or right-click the matching `.ps1` → *Run with PowerShell*. To pin: right-click a `.cmd` → *Create shortcut* → drag it to the Desktop or Start.

## Safety notes

* Only the **next** boot is affected; the permanent boot order is untouched.
* If the target entry can't be found, nothing happens (the script reports it and exits).
* Nothing here writes to disks, partitions, or bootloaders — only UEFI boot variables.

---

<a id="-tiếng-việt"></a>
# 🇻🇳 Tiếng Việt

Bộ công cụ một-cú-nhấp để khởi động lại máy dual-boot UEFI vào đúng HĐH bạn muốn.

Mỗi HĐH có **hai** nút:

* **Reboot to Windows** — lần boot kế tiếp vào Windows
* **Reboot to Linux** — lần boot kế tiếp vào Linux

Dùng nút *HĐH-còn-lại* để chuyển qua, hoặc nút *cùng-HĐH* để chỉ restart mà vẫn ở nguyên HĐH đang dùng (tiện khi thứ tự boot mặc định trỏ sang cái kia).

Tất cả chỉ đặt mục tiêu boot **một lần** của firmware UEFI rồi khởi động lại. Thứ tự boot vĩnh viễn **không** bị đổi — chỉ lần boot *kế tiếp* được chuyển hướng, sau đó mọi thứ trở lại bình thường.

## Cơ chế

* **Linux** dùng `efibootmgr -n <entry>` để đặt biến UEFI `BootNext` trỏ tới mục *Windows Boot Manager*.
* **Windows** dùng `bcdedit /set {fwbootmgr} bootsequence <guid>` để boot một lần vào mục firmware *Ubuntu*.

Đều là cơ chế UEFI chuẩn, có thể đảo ngược — không sửa phân vùng hay bootloader nào.

### Dùng được cho mọi máy (tự dò)

Không hard-code gì cả (không cố định ổ hay số boot entry). Entry đích được **tự dò lúc chạy**:

* **Windows** dò qua đường dẫn chuẩn `BOOTMGFW.EFI` — máy Windows nào cũng đúng.
* **Linux** dò qua tên entry firmware (`ubuntu`, `debian`, `fedora`, `arch`, `mint`, …) hoặc đường dẫn GRUB/shim (`grubx64.efi` / `shimx64.efi`).

Nếu dò nhầm (hoặc distro của bạn chưa được nhận), ép thủ công:

```sh
# Linux → Windows
reboot-to-windows.sh "Windows"      # hoặc số entry như 0006
```
```powershell
# Windows → Linux
reboot-to-linux.ps1 -Match fedora   # tên bất kỳ, hoặc {GUID}
```

## Yêu cầu

* Máy **UEFI** đã cài cả hai HĐH (không phải BIOS legacy).
* **Linux:** có `efibootmgr` (`sudo apt install efibootmgr`) và quyền reboot.
* **Windows:** launcher tự nâng quyền Administrator.
* Nếu **Secure Boot** chặn đổi biến boot, hãy chuyển boot trong phần firmware setup.

## Linux — cài đặt

```sh
cd linux
./install.sh
```

Lệnh này tạo icon **"Reboot to Windows"** và **"Reboot to Linux"** ra desktop và menu ứng dụng. Nhấp đúp một cái, xác nhận, máy khởi động lại vào HĐH đó.

> Đặt `BootNext` cần `sudo`. Chỉ chạy không hỏi mật khẩu nếu đã bật passwordless sudo cho `efibootmgr`; nếu chưa, chạy một lần từ terminal để nhập mật khẩu.

Chạy thủ công:

```sh
sudo ./reboot-to-windows.sh     # hoặc ~/.local/bin/reboot-to-windows sau khi cài
```

## Windows — cài đặt

Chép thư mục `windows/` ra chỗ tiện. Trong đó có hai launcher:

* **`Reboot to Linux.cmd`** — khởi động lại vào Linux
* **`Reboot to Windows.cmd`** — restart về lại Windows

Nhấp đúp một cái (nó tự nâng quyền, hỏi xác nhận, rồi reboot), hoặc chuột phải `.ps1` tương ứng → *Run with PowerShell*. Muốn ghim: chuột phải `.cmd` → *Create shortcut* → kéo ra Desktop hoặc Start.

## Lưu ý an toàn

* Chỉ ảnh hưởng lần boot **kế tiếp**; thứ tự boot vĩnh viễn giữ nguyên.
* Không tìm thấy mục đích thì không làm gì (script báo và thoát).
* Không ghi vào ổ đĩa/phân vùng/bootloader — chỉ đụng biến boot UEFI.
