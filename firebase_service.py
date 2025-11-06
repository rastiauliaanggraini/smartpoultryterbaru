
import firebase_admin
from firebase_admin import credentials, db
import os
from datetime import datetime

# --- Inisialisasi Firebase Admin SDK ---

# Ganti 'path/to/your/serviceAccountKey.json' dengan path absolut ke file kunci Anda.
# SANGAT PENTING: Jangan letakkan file kunci ini di direktori publik!
# Cara terbaik adalah menyimpannya di luar root web Anda dan memuatnya menggunakan path absolut,
# atau menggunakan variabel lingkungan untuk menyimpan path-nya.

try:
    # Path ke file service account key Anda
    cred_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'serviceAccountKey.json')

    cred = credentials.Certificate(cred_path)

    # Inisialisasi aplikasi Firebase dengan URL database Anda
    firebase_admin.initialize_app(cred, {
        'databaseURL': 'https://YOUR_DATABASE_NAME.firebaseio.com'  # <-- GANTI DENGAN URL DATABASE ANDA
    })
    print("Firebase Admin SDK berhasil diinisialisasi.")
except Exception as e:
    print(f"Gagal menginisialisasi Firebase Admin SDK: {e}")
    # Jika gagal, fungsi di bawah tidak akan bisa berjalan.
    # Pastikan path ke serviceAccountKey.json dan URL database sudah benar.


def send_sensor_data_to_firebase(temperature: float, humidity: float, noise: float, light: float):
    """
    Mengirim data sensor yang diterima ke Firebase Realtime Database.

    Args:
        temperature (float): Nilai suhu saat ini.
        humidity (float): Nilai kelembaban saat ini.
        noise (float): Nilai kebisingan dalam dB.
        light (float): Nilai intensitas cahaya dalam lux.
    """
    if not firebase_admin._apps:
        print("Firebase SDK belum diinisialisasi. Fungsi dibatalkan.")
        return

    try:
        # Dapatkan referensi ke root database atau path spesifik
        # Kita akan menyimpan data di bawah node 'sensors/latest'
        ref = db.reference('sensors/latest')

        # Dapatkan timestamp saat ini dalam format ISO 8601
        timestamp = datetime.utcnow().isoformat()

        # Gunakan metode update() untuk menulis atau memperbarui data
        # update() hanya akan mengubah field yang ditentukan tanpa menghapus yang lain.
        ref.update({
            'temperature': temperature,
            'humidity': humidity,
            'noise': noise,
            'light': light,
            'last_updated': timestamp
        })

        print(f"Data berhasil dikirim ke Firebase: Suhu={temperature}, Kelembaban={humidity}")

    except Exception as e:
        print(f"Terjadi error saat mengirim data ke Firebase: {e}")

# --- Contoh Penggunaan ---
# Anda bisa memanggil fungsi ini dari views.py Django Anda setiap kali
# ada data sensor baru yang masuk.
if __name__ == '__main__':
    # Ini hanya untuk demonstrasi. Hapus atau beri komentar bagian ini
    # saat diintegrasikan ke Django.
    print("Menjalankan contoh pengiriman data...")
    # Contoh data sensor
    temp_sensor = 25.5
    hum_sensor = 65.2
    noise_sensor = 45.0
    light_sensor = 15.0

    send_sensor_data_to_firebase(temp_sensor, hum_sensor, noise_sensor, light_sensor)
