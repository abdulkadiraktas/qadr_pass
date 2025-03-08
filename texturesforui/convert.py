import os
import imageio.v3 as iio
from PIL import Image
from concurrent.futures import ThreadPoolExecutor, as_completed

def convert_dds_to_png(dds_path):
    png_path = os.path.splitext(dds_path)[0] + '.png'
    try:
        image = iio.imread(dds_path)
        Image.fromarray(image).save(png_path)
        print(f"Dönüştürüldü: {dds_path} -> {png_path}")
    except Exception as e:
        print(f"Hata ({dds_path}): {e}")

def find_dds_files(root_dir):
    dds_files = []
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.lower().endswith('.dds'):
                dds_files.append(os.path.join(subdir, file))
    return dds_files

if __name__ == "__main__":
    klasor_yolu = "./"  # Başlangıç dizini
    dds_files = find_dds_files(klasor_yolu)

    # Thread sayısını CPU sayısına göre ayarla
    thread_sayisi = min(32, os.cpu_count() + 4)  # Optimal thread sayısı

    with ThreadPoolExecutor(max_workers=thread_sayisi) as executor:
        futures = [executor.submit(convert_dds_to_png, dds) for dds in dds_files]
        for future in as_completed(futures):
            pass  # Burada sonuçları bekliyoruz, isteğe bağlı işlem yapılabilir.
