# OwnaFarm Smart Contract - Complete Flow Documentation

Dokumen ini menjelaskan alur lengkap penggunaan smart contract OwnaFarm dari awal hingga akhir.
Ditujukan untuk tim Backend dan Frontend agar memahami setiap langkah dan parameter yang diperlukan.

---

## Table of Contents

1. [Daftar Contract](#1-daftar-contract)
2. [Token Information](#2-token-information)
3. [Status Invoice](#3-status-invoice)
4. [Phase 1: Setup (Deployment)](#phase-1-setup-deployment)
5. [Phase 2: Farmer - Submit Invoice](#phase-2-farmer---submit-invoice)
6. [Phase 3: Admin - Approve/Reject Invoice](#phase-3-admin---approvereject-invoice)
7. [Phase 4: Investor - Investasi](#phase-4-investor---investasi)
8. [Phase 5: Investor - Harvest](#phase-5-investor---harvest)
9. [Error Reference](#error-reference)
10. [Role & Permission](#role--permission)
11. [Event Reference](#event-reference)
12. [Code Snippets untuk Frontend](#code-snippets-untuk-frontend)

---

## 1. Daftar Contract

| No  | Contract      | Deskripsi                                            |
| --- | ------------- | ---------------------------------------------------- |
| 1   | GoldToken     | Token ERC20 sebagai mata uang utama                  |
| 2   | GoldFaucet    | Faucet untuk mendapatkan GOLD gratis (testing)       |
| 3   | OwnaFarmNFT   | Contract utama untuk invoice, investasi, dan harvest |
| 4   | OwnaFarmVault | Penyimpanan yield reserve (opsional)                 |

---

## 2. Token Information

| Property       | Value            |
| -------------- | ---------------- |
| Token Name     | OwnaFarm Gold    |
| Token Symbol   | GOLD             |
| Decimals       | 18               |
| Initial Supply | 100,000,000 GOLD |

Karena decimals = 18, maka:

| Human Readable | Raw Value (Wei)           | Penjelasan      |
| -------------- | ------------------------- | --------------- |
| 1 GOLD         | 1000000000000000000       | 1 x 10^18       |
| 100 GOLD       | 100000000000000000000     | 100 x 10^18     |
| 1,000 GOLD     | 1000000000000000000000    | 1000 x 10^18    |
| 10,000 GOLD    | 10000000000000000000000   | 10000 x 10^18   |
| 100,000 GOLD   | 100000000000000000000000  | 100000 x 10^18  |
| 1,000,000 GOLD | 1000000000000000000000000 | 1000000 x 10^18 |

---

## 3. Status Invoice

| Code | Status    | Deskripsi                         | Aksi Selanjutnya              |
| ---- | --------- | --------------------------------- | ----------------------------- |
| 0    | Pending   | Invoice baru dibuat               | Menunggu admin approve/reject |
| 1    | Approved  | Invoice disetujui admin           | Investor dapat berinvestasi   |
| 2    | Rejected  | Invoice ditolak admin             | Tidak ada aksi (final)        |
| 3    | Funded    | Fully funded (investasi = target) | Menunggu mature untuk harvest |
| 4    | Completed | Semua investor sudah harvest      | Tidak ada aksi (final)        |

---

## Phase 1: Setup (Deployment)

Phase ini dilakukan oleh deployer/admin saat pertama kali men-deploy contract.

### Step 1.1: Deploy GoldToken

| Item        | Value                                         |
| ----------- | --------------------------------------------- |
| Contract    | GoldToken.sol                                 |
| Constructor | Tidak ada parameter                           |
| Output      | Contract address GoldToken                    |
| Catatan     | 100,000,000 GOLD otomatis dikirim ke deployer |

---

### Step 1.2: Deploy GoldFaucet

| Item     | Value                       |
| -------- | --------------------------- |
| Contract | GoldFaucet.sol              |
| Output   | Contract address GoldFaucet |

Constructor Parameters:

| Parameter | Tipe    | Deskripsi         | Sumber          |
| --------- | ------- | ----------------- | --------------- |
| gold\_    | address | Address GoldToken | Output Step 1.1 |

---

### Step 1.3: Deploy OwnaFarmNFT

| Item     | Value                        |
| -------- | ---------------------------- |
| Contract | OwnaFarmNFT.sol              |
| Output   | Contract address OwnaFarmNFT |

Constructor Parameters:

| Parameter | Tipe    | Deskripsi         | Sumber          |
| --------- | ------- | ----------------- | --------------- |
| gold\_    | address | Address GoldToken | Output Step 1.1 |

---

### Step 1.4: Deploy OwnaFarmVault (Opsional)

| Item     | Value                          |
| -------- | ------------------------------ |
| Contract | OwnaFarmVault.sol              |
| Output   | Contract address OwnaFarmVault |

Constructor Parameters:

| Parameter | Tipe    | Deskripsi         | Sumber          |
| --------- | ------- | ----------------- | --------------- |
| gold\_    | address | Address GoldToken | Output Step 1.1 |

---

### Step 1.5: Fund Faucet dengan GOLD

Admin mengirim GOLD ke faucet agar user bisa claim.

| Item     | Value     |
| -------- | --------- |
| Contract | GoldToken |
| Function | transfer  |

Parameters:

| Parameter | Tipe    | Deskripsi                 | Contoh               |
| --------- | ------- | ------------------------- | -------------------- |
| to        | address | Address GoldFaucet        | Output Step 1.2      |
| amount    | uint256 | Jumlah GOLD (18 decimals) | Lihat tabel di bawah |

Amount Examples:

| Ingin Kirim     | Nilai amount (raw)         |
| --------------- | -------------------------- |
| 1,000,000 GOLD  | 1000000000000000000000000  |
| 10,000,000 GOLD | 10000000000000000000000000 |

---

## Phase 2: Farmer - Submit Invoice

Farmer adalah pengguna yang mengajukan invoice untuk mendapatkan pendanaan.

### Step 2.1: Submit Invoice

| Item     | Value                            |
| -------- | -------------------------------- |
| Contract | OwnaFarmNFT                      |
| Function | submitInvoice                    |
| Caller   | Siapa saja (akan menjadi farmer) |
| Output   | tokenId (uint256)                |

---

#### Parameter 1: offtakerId

| Property       | Value                                  |
| -------------- | -------------------------------------- |
| Nama Parameter | offtakerId                             |
| Tipe Data      | bytes32                                |
| Panjang        | 32 bytes (64 karakter hex + prefix 0x) |

Deskripsi:

- ID unik untuk mengidentifikasi offtaker (pembeli hasil panen)
- Dibuat oleh sistem backend atau admin
- Digunakan untuk tracking dan audit

Cara Membuat:

| Dari           | Hasil bytes32                                                     |
| -------------- | ----------------------------------------------------------------- |
| "OFFTAKER-001" | 0x4f46465441⁠4b45522d30303100000000000000000000000000000000000000 |
| "BUYER-ABC"    | 0x42555945522d41424300000000000000000000000000000000000000000000  |

Code untuk generate:

```javascript
// JavaScript dengan ethers.js
const offtakerId = ethers.utils.formatBytes32String("OFFTAKER-001");
```

---

#### Parameter 2: targetFund

| Property       | Value                                   |
| -------------- | --------------------------------------- |
| Nama Parameter | targetFund                              |
| Tipe Data      | uint128                                 |
| Decimals       | 18 (sama dengan GOLD token)             |
| Minimum        | 1 (0.000000000000000001 GOLD)           |
| Maximum        | 340,282,366,920,938,463,463,374,607,431 |

Deskripsi:

- Total dana yang ingin dikumpulkan oleh farmer
- Nilai dalam format raw (sudah dikalikan 10^18)
- Ditentukan sendiri oleh farmer

Tabel Konversi:

| Target (GOLD) | targetFund (raw)         |
| ------------- | ------------------------ |
| 1,000 GOLD    | 1000000000000000000000   |
| 5,000 GOLD    | 5000000000000000000000   |
| 10,000 GOLD   | 10000000000000000000000  |
| 50,000 GOLD   | 50000000000000000000000  |
| 100,000 GOLD  | 100000000000000000000000 |

Formula:

```
targetFund = jumlah_GOLD x 10^18
```

Code untuk convert:

```javascript
// JavaScript dengan ethers.js
const goldAmount = 5000; // 5000 GOLD
const targetFund = ethers.utils.parseEther(goldAmount.toString());
// Result: BigNumber { value: "5000000000000000000000" }
```

---

#### Parameter 3: yieldBps

| Property       | Value              |
| -------------- | ------------------ |
| Nama Parameter | yieldBps           |
| Tipe Data      | uint16             |
| Satuan         | Basis Points (bps) |
| 1 bps =        | 0.01%              |
| Minimum        | 0 (0%)             |
| Maximum        | 65535 (655.35%)    |

Deskripsi:

- Persentase keuntungan yang akan diterima investor
- Menggunakan basis points untuk presisi tinggi
- Ditentukan oleh farmer

Tabel Konversi:

| Yield yang Diinginkan | yieldBps |
| --------------------- | -------- |
| 1%                    | 100      |
| 2.5%                  | 250      |
| 5%                    | 500      |
| 7.5%                  | 750      |
| 10%                   | 1000     |
| 12.5%                 | 1250     |
| 15%                   | 1500     |
| 20%                   | 2000     |
| 25%                   | 2500     |
| 50%                   | 5000     |
| 100%                  | 10000    |

Formula Perhitungan Yield:

```
yieldAmount = (principal x yieldBps) / 10000
```

Contoh Perhitungan:

| Principal   | yieldBps   | Yield      | Total Return |
| ----------- | ---------- | ---------- | ------------ |
| 1,000 GOLD  | 1000 (10%) | 100 GOLD   | 1,100 GOLD   |
| 5,000 GOLD  | 1500 (15%) | 750 GOLD   | 5,750 GOLD   |
| 10,000 GOLD | 2000 (20%) | 2,000 GOLD | 12,000 GOLD  |

---

#### Parameter 4: duration

| Property       | Value                            |
| -------------- | -------------------------------- |
| Nama Parameter | duration                         |
| Tipe Data      | uint32                           |
| Satuan         | Detik (seconds)                  |
| Minimum        | 0                                |
| Maximum        | 4,294,967,295 detik (~136 tahun) |

Deskripsi:

- Lama waktu investasi sebelum investor bisa harvest
- Dihitung dari waktu investor melakukan investasi
- Ditentukan oleh farmer

Tabel Konversi:

| Durasi   | duration (detik) |
| -------- | ---------------- |
| 1 jam    | 3600             |
| 12 jam   | 43200            |
| 1 hari   | 86400            |
| 3 hari   | 259200           |
| 7 hari   | 604800           |
| 14 hari  | 1209600          |
| 30 hari  | 2592000          |
| 60 hari  | 5184000          |
| 90 hari  | 7776000          |
| 180 hari | 15552000         |
| 365 hari | 31536000         |

Formula:

```
duration = hari x 24 x 60 x 60
duration = hari x 86400
```

Code untuk convert:

```javascript
const days = 30;
const duration = days * 24 * 60 * 60; // 2592000
```

---

#### Contoh Lengkap Submit Invoice

Skenario: Farmer ingin mengumpulkan 10,000 GOLD dengan yield 15% selama 30 hari

| Parameter  | Nilai                                                             |
| ---------- | ----------------------------------------------------------------- |
| offtakerId | 0x4f46465441⁠4b45522d30303100000000000000000000000000000000000000 |
| targetFund | 10000000000000000000000                                           |
| yieldBps   | 1500                                                              |
| duration   | 2592000                                                           |

---

### Step 2.2: Verifikasi Invoice

| Item     | Value           |
| -------- | --------------- |
| Contract | OwnaFarmNFT     |
| Function | invoices (read) |

Parameter:

| Parameter | Tipe    | Deskripsi  | Sumber                               |
| --------- | ------- | ---------- | ------------------------------------ |
| tokenId   | uint256 | ID invoice | Dari return submitInvoice atau event |

Return Value:

| Field        | Tipe    | Deskripsi                         |
| ------------ | ------- | --------------------------------- |
| farmer       | address | Address farmer                    |
| targetFund   | uint128 | Target dana (raw, 18 decimals)    |
| fundedAmount | uint128 | Dana terkumpul (raw, 18 decimals) |
| yieldBps     | uint16  | Yield dalam basis points          |
| duration     | uint32  | Durasi dalam detik                |
| createdAt    | uint32  | Timestamp pembuatan               |
| status       | uint8   | Status invoice (0-4)              |
| offtakerId   | bytes32 | ID offtaker                       |

---

## Phase 3: Admin - Approve/Reject Invoice

Admin mereview invoice dan memutuskan approval.

### Step 3.1: Lihat Invoice Pending

| Item     | Value                     |
| -------- | ------------------------- |
| Contract | OwnaFarmNFT               |
| Function | getPendingInvoices (read) |

Parameters:

| Parameter | Tipe    | Deskripsi                     | Contoh |
| --------- | ------- | ----------------------------- | ------ |
| offset    | uint256 | Index awal (untuk pagination) | 0      |
| limit     | uint256 | Jumlah data maksimal          | 10     |

Return Value:

| Field | Tipe      | Deskripsi          |
| ----- | --------- | ------------------ |
| ids   | uint256[] | Array tokenId      |
| data  | Invoice[] | Array data invoice |

---

### Step 3.2: Lihat Jumlah Invoice Pending

| Item       | Value                            |
| ---------- | -------------------------------- |
| Contract   | OwnaFarmNFT                      |
| Function   | getPendingCount (read)           |
| Parameters | Tidak ada                        |
| Return     | uint256 (jumlah invoice pending) |

---

### Step 3.3: Approve Invoice

| Item     | Value           |
| -------- | --------------- |
| Contract | OwnaFarmNFT     |
| Function | approveInvoice  |
| Caller   | ADMIN_ROLE only |

Parameter:

| Parameter | Tipe    | Deskripsi  | Sumber                  |
| --------- | ------- | ---------- | ----------------------- |
| tokenId   | uint256 | ID invoice | Dari getPendingInvoices |

Efek Setelah Approve:

- Status berubah: Pending (0) -> Approved (1)
- Invoice masuk ke list available
- Investor dapat invest

---

### Step 3.4: Reject Invoice (Alternatif)

| Item     | Value           |
| -------- | --------------- |
| Contract | OwnaFarmNFT     |
| Function | rejectInvoice   |
| Caller   | ADMIN_ROLE only |

Parameter:

| Parameter | Tipe    | Deskripsi  | Sumber                  |
| --------- | ------- | ---------- | ----------------------- |
| tokenId   | uint256 | ID invoice | Dari getPendingInvoices |

Efek Setelah Reject:

- Status berubah: Pending (0) -> Rejected (2)
- Invoice tidak dapat diinvestasikan

---

## Phase 4: Investor - Investasi

Investor menginvestasikan GOLD ke invoice yang sudah approved.

### Step 4.1: Claim GOLD dari Faucet (Testing)

| Item         | Value                 |
| ------------ | --------------------- |
| Contract     | GoldFaucet            |
| Function     | claim                 |
| Parameters   | Tidak ada             |
| Claim Amount | 10,000 GOLD per klaim |
| Cooldown     | 24 jam                |

---

#### Cek Apakah Bisa Claim

| Item     | Value           |
| -------- | --------------- |
| Contract | GoldFaucet      |
| Function | canClaim (read) |

Parameter:

| Parameter | Tipe    | Deskripsi      |
| --------- | ------- | -------------- |
| user      | address | Wallet address |

Return:

| Value | Arti           |
| ----- | -------------- |
| true  | Bisa claim     |
| false | Masih cooldown |

---

#### Cek Waktu Cooldown

| Item     | Value                     |
| -------- | ------------------------- |
| Contract | GoldFaucet                |
| Function | timeUntilNextClaim (read) |

Parameter:

| Parameter | Tipe    | Deskripsi      |
| --------- | ------- | -------------- |
| user      | address | Wallet address |

Return:

| Value | Arti                            |
| ----- | ------------------------------- |
| 0     | Bisa claim sekarang             |
| > 0   | Detik tersisa sampai bisa claim |

---

### Step 4.2: Lihat Invoice Available

| Item     | Value                       |
| -------- | --------------------------- |
| Contract | OwnaFarmNFT                 |
| Function | getAvailableInvoices (read) |

Parameters:

| Parameter | Tipe    | Deskripsi       | Contoh |
| --------- | ------- | --------------- | ------ |
| offset    | uint256 | Index awal      | 0      |
| limit     | uint256 | Jumlah maksimal | 10     |

Invoice Available = Status Approved (1) dan belum fully funded

---

### Step 4.3: Approve GOLD Token (WAJIB)

| Item     | Value                          |
| -------- | ------------------------------ |
| Contract | GoldToken                      |
| Function | approve                        |
| Catatan  | HARUS dilakukan SEBELUM invest |

Parameters:

| Parameter | Tipe    | Deskripsi                      | Sumber                  |
| --------- | ------- | ------------------------------ | ----------------------- |
| spender   | address | Address OwnaFarmNFT            | Dari deployment         |
| amount    | uint256 | Jumlah GOLD (raw, 18 decimals) | Minimal = jumlah invest |

Contoh:

| Ingin Invest | amount untuk approve                                                           |
| ------------ | ------------------------------------------------------------------------------ |
| 1,000 GOLD   | 1000000000000000000000                                                         |
| 5,000 GOLD   | 5000000000000000000000                                                         |
| Unlimited    | 115792089237316195423570985008687907853269984665640564039457584007913129639935 |

Code untuk approve unlimited:

```javascript
const maxApproval = ethers.constants.MaxUint256;
await goldToken.approve(ownaFarmNFTAddress, maxApproval);
```

---

### Step 4.4: Cek Allowance (Opsional)

| Item     | Value            |
| -------- | ---------------- |
| Contract | GoldToken        |
| Function | allowance (read) |

Parameters:

| Parameter | Tipe    | Deskripsi           |
| --------- | ------- | ------------------- |
| owner     | address | Wallet investor     |
| spender   | address | Address OwnaFarmNFT |

Return: Jumlah GOLD yang di-approve (raw, 18 decimals)

---

### Step 4.5: Invest

| Item     | Value       |
| -------- | ----------- |
| Contract | OwnaFarmNFT |
| Function | invest      |

Parameters:

| Parameter | Tipe    | Decimals | Deskripsi         | Sumber                    |
| --------- | ------- | -------- | ----------------- | ------------------------- |
| tokenId   | uint256 | -        | ID invoice        | Dari getAvailableInvoices |
| amount    | uint128 | 18       | Jumlah GOLD (raw) | Ditentukan investor       |

Validasi:

- Invoice status = Approved (1)
- fundedAmount + amount <= targetFund
- Investor punya cukup GOLD
- Allowance >= amount

Efek Setelah Invest:

- GOLD ditransfer ke contract
- Investor dapat 1 NFT (ERC1155)
- Investment record tersimpan
- Jika fundedAmount = targetFund, status -> Funded (3)

Contoh:

| Ingin Invest | amount                 |
| ------------ | ---------------------- |
| 500 GOLD     | 500000000000000000000  |
| 1,000 GOLD   | 1000000000000000000000 |
| 2,500 GOLD   | 2500000000000000000000 |
| 5,000 GOLD   | 5000000000000000000000 |

---

### Step 4.6: Verifikasi Investment

| Item     | Value                |
| -------- | -------------------- |
| Contract | OwnaFarmNFT          |
| Function | getInvestment (read) |

Parameters:

| Parameter    | Tipe    | Deskripsi        | Sumber       |
| ------------ | ------- | ---------------- | ------------ |
| investor     | address | Wallet investor  | -            |
| investmentId | uint256 | Index investment | 0, 1, 2, ... |

Catatan: investmentId adalah index yang increment per investor (mulai dari 0)

Return:

| Field      | Tipe    | Decimals | Deskripsi                  |
| ---------- | ------- | -------- | -------------------------- |
| amount     | uint128 | 18       | Jumlah investasi (raw)     |
| tokenId    | uint32  | -        | ID invoice                 |
| investedAt | uint32  | -        | Timestamp investasi (unix) |
| claimed    | bool    | -        | Sudah harvest atau belum   |

---

### Step 4.7: Cek Jumlah Investment

| Item     | Value                  |
| -------- | ---------------------- |
| Contract | OwnaFarmNFT            |
| Function | investmentCount (read) |

Parameter:

| Parameter | Tipe    | Deskripsi       |
| --------- | ------- | --------------- |
| investor  | address | Wallet investor |

Return: Jumlah total investment yang dimiliki (uint256)

---

### Step 4.8: Cek NFT Balance

| Item     | Value                      |
| -------- | -------------------------- |
| Contract | OwnaFarmNFT                |
| Function | balanceOf (read) - ERC1155 |

Parameters:

| Parameter | Tipe    | Deskripsi       |
| --------- | ------- | --------------- |
| account   | address | Wallet investor |
| id        | uint256 | tokenId invoice |

Return: Jumlah NFT untuk tokenId tersebut

---

## Phase 5: Investor - Harvest

Setelah durasi berakhir, investor mengklaim principal + yield.

### Step 5.1: Cek Maturity

Investment bisa di-harvest jika waktu sekarang >= waktu invest + durasi

Formula:

```
canHarvest = block.timestamp >= investedAt + duration
```

Code untuk cek:

```javascript
const investment = await ownaFarmNFT.getInvestment(
  investorAddress,
  investmentId
);
const invoice = await ownaFarmNFT.invoices(investment.tokenId);

const investedAt = investment.investedAt; // unix timestamp
const duration = invoice.duration; // detik
const maturityTime = investedAt + duration; // unix timestamp

const now = Math.floor(Date.now() / 1000);
const isMature = now >= maturityTime;
const secondsRemaining = isMature ? 0 : maturityTime - now;
```

---

### Step 5.2: Pastikan Contract Punya GOLD

Contract harus punya cukup GOLD untuk bayar principal + yield.

| Item     | Value            |
| -------- | ---------------- |
| Contract | GoldToken        |
| Function | balanceOf (read) |

Parameter:

| Parameter | Tipe    | Deskripsi           |
| --------- | ------- | ------------------- |
| account   | address | Address OwnaFarmNFT |

Jika tidak cukup, admin transfer GOLD ke contract.

---

### Step 5.3: Harvest

| Item     | Value       |
| -------- | ----------- |
| Contract | OwnaFarmNFT |
| Function | harvest     |

Parameter:

| Parameter    | Tipe    | Deskripsi        | Sumber               |
| ------------ | ------- | ---------------- | -------------------- |
| investmentId | uint256 | Index investment | Dari investmentCount |

Validasi:

- Investment ada (amount > 0)
- Belum claimed (claimed = false)
- Sudah mature (timestamp >= investedAt + duration)

Efek Setelah Harvest:

- Investment.claimed = true
- NFT di-burn
- Investor terima principal + yield

---

### Perhitungan Return

| Item      | Formula                        |
| --------- | ------------------------------ |
| Principal | amount yang diinvestasikan     |
| Yield     | (principal x yieldBps) / 10000 |
| Total     | principal + yield              |

Contoh:

| Principal   | yieldBps   | Yield      | Total Return |
| ----------- | ---------- | ---------- | ------------ |
| 1,000 GOLD  | 1000 (10%) | 100 GOLD   | 1,100 GOLD   |
| 2,500 GOLD  | 1500 (15%) | 375 GOLD   | 2,875 GOLD   |
| 5,000 GOLD  | 2000 (20%) | 1,000 GOLD | 6,000 GOLD   |
| 10,000 GOLD | 1000 (10%) | 1,000 GOLD | 11,000 GOLD  |

---

### Step 5.4: Verifikasi Harvest

Cek Investment:

| Contract    | Function      | Expected               |
| ----------- | ------------- | ---------------------- |
| OwnaFarmNFT | getInvestment | claimed = true         |
| OwnaFarmNFT | balanceOf     | NFT balance berkurang  |
| GoldToken   | balanceOf     | GOLD balance bertambah |

---

## Error Reference

| Error               | Contract      | Penyebab                 | Solusi                    |
| ------------------- | ------------- | ------------------------ | ------------------------- |
| CooldownActive      | GoldFaucet    | User masih cooldown      | Tunggu 24 jam             |
| FaucetEmpty         | GoldFaucet    | Faucet kehabisan GOLD    | Admin deposit             |
| InvoiceNotApproved  | OwnaFarmNFT   | Status bukan Approved    | Tunggu admin approve      |
| ExceedsTarget       | OwnaFarmNFT   | amount > sisa target     | Kurangi amount            |
| AlreadyClaimed      | OwnaFarmNFT   | Sudah di-harvest         | -                         |
| NotMature           | OwnaFarmNFT   | Belum jatuh tempo        | Tunggu durasi selesai     |
| InvalidInvestment   | OwnaFarmNFT   | Investment tidak ada     | Cek investmentId          |
| NotPending          | OwnaFarmNFT   | Status bukan Pending     | Tidak bisa approve/reject |
| OnlyFarmNFT         | OwnaFarmVault | Caller bukan OwnaFarmNFT | -                         |
| InsufficientReserve | OwnaFarmVault | Reserve tidak cukup      | Admin deposit             |
| FarmNFTAlreadySet   | OwnaFarmVault | Sudah di-set             | Tidak bisa diubah         |

---

## Role & Permission

### ADMIN_ROLE

| Contract      | Functions                                              |
| ------------- | ------------------------------------------------------ |
| GoldFaucet    | setClaimAmount, setCooldownTime, withdraw, withdrawAll |
| OwnaFarmNFT   | approveInvoice, rejectInvoice, setTokenURI             |
| OwnaFarmVault | setFarmNFT, depositYield                               |

### DEFAULT_ADMIN_ROLE

| Contract      | Functions                                                 |
| ------------- | --------------------------------------------------------- |
| GoldFaucet    | Semua ADMIN_ROLE + grant/revoke roles                     |
| OwnaFarmNFT   | Semua ADMIN_ROLE + grant/revoke roles                     |
| OwnaFarmVault | Semua ADMIN_ROLE + emergencyWithdraw + grant/revoke roles |

### Public (Siapa Saja)

| Contract    | Functions                       |
| ----------- | ------------------------------- |
| GoldToken   | transfer, approve, transferFrom |
| GoldFaucet  | claim, deposit                  |
| OwnaFarmNFT | submitInvoice, invest, harvest  |

---

## Event Reference

### GoldToken Events

| Event    | Trigger         | Parameters            |
| -------- | --------------- | --------------------- |
| Transfer | Setiap transfer | from, to, value       |
| Approval | Setiap approve  | owner, spender, value |
| Minted   | Saat mint       | to, amount            |

### GoldFaucet Events

| Event              | Trigger        | Parameters        |
| ------------------ | -------------- | ----------------- |
| Claimed            | User claim     | user, amount      |
| Deposited          | Ada deposit    | depositor, amount |
| ClaimAmountUpdated | Admin update   | newAmount         |
| CooldownUpdated    | Admin update   | newCooldown       |
| Withdrawn          | Admin withdraw | to, amount        |

### OwnaFarmNFT Events

| Event              | Trigger          | Parameters                               |
| ------------------ | ---------------- | ---------------------------------------- |
| InvoiceSubmitted   | Farmer submit    | tokenId, farmer, offtakerId, target      |
| InvoiceApproved    | Admin approve    | tokenId, approver                        |
| InvoiceRejected    | Admin reject     | tokenId, rejector                        |
| Invested           | Investor invest  | investor, tokenId, amount, investmentId  |
| InvoiceFullyFunded | Target tercapai  | tokenId                                  |
| Harvested          | Investor harvest | investor, investmentId, principal, yield |

### OwnaFarmVault Events

| Event          | Trigger        | Parameters |
| -------------- | -------------- | ---------- |
| YieldDeposited | Admin deposit  | amount     |
| YieldWithdrawn | Yield ditarik  | to, amount |
| FarmNFTSet     | Address di-set | newFarmNFT |

---

## Code Snippets untuk Frontend

### Wei Conversion

```javascript
import { ethers } from "ethers";

// GOLD ke Wei (untuk input ke contract)
const goldAmount = 1000;
const weiAmount = ethers.utils.parseEther(goldAmount.toString());
// Result: BigNumber "1000000000000000000000"

// Wei ke GOLD (untuk display ke user)
const weiValue = "1000000000000000000000";
const goldValue = ethers.utils.formatEther(weiValue);
// Result: "1000.0"
```

---

### Bytes32 Conversion

```javascript
import { ethers } from "ethers";

// String ke Bytes32 (untuk offtakerId)
const offtakerId = ethers.utils.formatBytes32String("OFFTAKER-001");
// Result: "0x4f46465441⁠4b45522d303031..."

// Bytes32 ke String (untuk display)
const bytes32 = "0x4f46465441⁠4b45522d303031...";
const text = ethers.utils.parseBytes32String(bytes32);
// Result: "OFFTAKER-001"
```

---

### Timestamp Handling

```javascript
// Current timestamp (detik)
const now = Math.floor(Date.now() / 1000);

// Cek mature
const maturityTime = investment.investedAt + invoice.duration;
const isMature = now >= maturityTime;

// Hitung sisa waktu
const remaining = maturityTime - now; // dalam detik
const days = Math.floor(remaining / 86400);
const hours = Math.floor((remaining % 86400) / 3600);
const minutes = Math.floor((remaining % 3600) / 60);

console.log(`${days}d ${hours}h ${minutes}m remaining`);
```

---

### BigNumber Operations

```javascript
import { ethers } from "ethers";

// Perbandingan
const isFunded = fundedAmount.gte(targetFund); // greater than or equal

// Pengurangan
const remaining = targetFund.sub(fundedAmount);

// Perhitungan yield
const yieldAmount = principal.mul(yieldBps).div(10000);

// Total return
const totalReturn = principal.add(yieldAmount);
```

---

### Complete Investment Example

```javascript
import { ethers } from "ethers";

async function investToInvoice(
  signer,
  goldTokenAddress,
  ownaFarmNFTAddress,
  tokenId,
  goldAmount
) {
  const goldToken = new ethers.Contract(goldTokenAddress, goldTokenABI, signer);
  const ownaFarmNFT = new ethers.Contract(
    ownaFarmNFTAddress,
    ownaFarmNFTABI,
    signer
  );

  // 1. Convert amount
  const amount = ethers.utils.parseEther(goldAmount.toString());

  // 2. Check allowance
  const currentAllowance = await goldToken.allowance(
    signer.address,
    ownaFarmNFTAddress
  );

  // 3. Approve if needed
  if (currentAllowance.lt(amount)) {
    const approveTx = await goldToken.approve(
      ownaFarmNFTAddress,
      ethers.constants.MaxUint256
    );
    await approveTx.wait();
    console.log("Approved");
  }

  // 4. Invest
  const investTx = await ownaFarmNFT.invest(tokenId, amount);
  const receipt = await investTx.wait();
  console.log("Invested:", receipt.transactionHash);

  // 5. Get investment ID from event
  const event = receipt.events.find((e) => e.event === "Invested");
  const investmentId = event.args.investmentId;
  console.log("Investment ID:", investmentId.toString());

  return investmentId;
}
```

---

### Complete Harvest Example

```javascript
import { ethers } from "ethers";

async function harvestInvestment(signer, ownaFarmNFTAddress, investmentId) {
  const ownaFarmNFT = new ethers.Contract(
    ownaFarmNFTAddress,
    ownaFarmNFTABI,
    signer
  );

  // 1. Get investment data
  const investment = await ownaFarmNFT.getInvestment(
    signer.address,
    investmentId
  );

  // 2. Check if already claimed
  if (investment.claimed) {
    throw new Error("Already claimed");
  }

  // 3. Get invoice for duration
  const invoice = await ownaFarmNFT.invoices(investment.tokenId);

  // 4. Check maturity
  const now = Math.floor(Date.now() / 1000);
  const maturityTime = investment.investedAt + invoice.duration;

  if (now < maturityTime) {
    const remaining = maturityTime - now;
    throw new Error(
      `Not mature. ${Math.floor(remaining / 86400)} days remaining`
    );
  }

  // 5. Calculate expected return
  const principal = investment.amount;
  const yieldAmount = principal.mul(invoice.yieldBps).div(10000);
  const totalReturn = principal.add(yieldAmount);

  console.log(
    "Expected return:",
    ethers.utils.formatEther(totalReturn),
    "GOLD"
  );

  // 6. Harvest
  const harvestTx = await ownaFarmNFT.harvest(investmentId);
  const receipt = await harvestTx.wait();
  console.log("Harvested:", receipt.transactionHash);

  return receipt;
}
```
