import os
import pandas as pd

df = pd.read_csv('data/labels.csv')
df = df.dropna(subset=['face_shape'])
print(f'Valid rows: {len(df)}')
print(df['face_shape'].value_counts())

img_path = os.path.join('data/images', df.iloc[0]['image_name'])
print(f'First image path: {img_path}')
print(f'First image exists: {os.path.exists(img_path)}')