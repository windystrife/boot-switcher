# 🔁 boot-switcher

Tiny one-click helpers to reboot a UEFI dual-boot PC straight into "the other OS".

* On **Linux** → **Reboot to Windows**
* On **Windows** → **Reboot to Linux**

Both set the UEFI firmware's **one-time** boot target and then reboot. Your permanent boot order is never changed — only the *next* boot is redirected, so everything goes back to normal afterwards.

> 🇻🇳 **Tiếng Việt bên dưới** — [nhảy tới](#-tiếng-việt)

---

## How it works

* **Linux** uses `efibootmgr -n <entry>` to set the `BootNext` UEFI variable to the *Windows Boot Manager* entry.
* **Windows** uses `bcdedit /set {fwbootmgr} bootsequence <guid>` to set a one-time boot into the *Ubuntu* firmware entry.

Both are the standard, reversible UEFI mechanisms — no partition or bootloader is modified.

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

This puts a **"Reboot to Windows"** icon on your desktop and in the applications menu. Double-click it, confirm, and the PC restarts into Windows.

> Setting `BootNext` needs `sudo`. It runs without a prompt only if passwordless sudo is enabled for `efibootmgr`; otherwise launch it once from a terminal to type your password.

Run manually instead:

```sh
sudo ./reboot-to-windows.sh     # or ~/.local/bin/reboot-to-windows after install
```

## Windows — install

Copy the `windows/` folder somewhere handy, then either:

* double-click **`Reboot to Linux.cmd`**, or
* right-click **`reboot-to-linux.ps1`** → *Run with PowerShell*.

It self-elevates, finds the Ubuntu firmware entry, asks for confirmation, and reboots into Linux. To pin it: right-click `Reboot to Linux.cmd` → *Create shortcut* → drag the shortcut to the Desktop or Start.

## Safety notes

* Only the **next** boot is affected; the permanent boot order is untouched.
* If the target entry can't be found, nothing happens (the script reports it and exits).
* Nothing here writes to disks, partitions, or bootloaders — only UEFI boot variables.

---

<a id="-tiếng-việt"></a>
# 🇻🇳 Tiếng Việt

Bộ công cụ một-cú-nhấp để khởi động lại máy dual-boot UEFI vào thẳng "hệ điều hành còn lại".

* Trên **Linux** → **Khởi động lại vào Windows**
* Trên **Windows** → **Khởi động lại vào Linux**

Cả hai chỉ đặt mục tiêu boot **một lần** của firmware UEFI rồi khởi động lại. Thứ tự boot vĩnh viễn **không** bị đổi — chỉ lần boot *kế tiếp* được chuyển hướng, sau đó mọi thứ trở lại bình thường.

## Cơ chế

* **Linux** dùng `efibootmgr -n <entry>` để đặt biến UEFI `BootNext` trỏ tới mục *Windows Boot Manager*.
* **Windows** dùng `bcdedit /set {fwbootmgr} bootsequence <guid>` để boot một lần vào mục firmware *Ubuntu*.

Đều là cơ chế UEFI chuẩn, có thể đảo ngược — không sửa phân vùng hay bootloader nào.

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

Lệnh này tạo icon **"Reboot to Windows"** ra desktop và menu ứng dụng. Nhấp đúp, xác nhận, máy khởi động lại vào Windows.

> Đặt `BootNext` cần `sudo`. Chỉ chạy không hỏi mật khẩu nếu đã bật passwordless sudo cho `efibootmgr`; nếu chưa, chạy một lần từ terminal để nhập mật khẩu.

Chạy thủ công:

```sh
sudo ./reboot-to-windows.sh     # hoặc ~/.local/bin/reboot-to-windows sau khi cài
```

## Windows — cài đặt

Chép thư mục `windows/` ra chỗ tiện, rồi:

* nhấp đúp **`Reboot to Linux.cmd`**, hoặc
* chuột phải **`reboot-to-linux.ps1`** → *Run with PowerShell*.

Nó tự nâng quyền, tìm mục firmware Ubuntu, hỏi xác nhận, rồi khởi động lại vào Linux. Muốn ghim: chuột phải `Reboot to Linux.cmd` → *Create shortcut* → kéo ra Desktop hoặc Start.

## Lưu ý an toàn

* Chỉ ảnh hưởng lần boot **kế tiếp**; thứ tự boot vĩnh viễn giữ nguyên.
* Không tìm thấy mục đích thì không làm gì (script báo và thoát).
* Không ghi vào ổ đĩa/phân vùng/bootloader — chỉ đụng biến boot UEFI.
