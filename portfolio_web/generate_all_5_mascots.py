import os
from PIL import Image, ImageDraw

base_out = r'c:\Users\MyBook Hype AMD\KULIAH SISTEM INFORMASI\project apa aja\hitung_gaji_segari\segari_salary_tracker_app\assets\sprites'
web_out = r'c:\Users\MyBook Hype AMD\KULIAH SISTEM INFORMASI\project apa aja\hitung_gaji_segari\portfolio_web\sprites'

# Standard Colors
BK = (20, 20, 25, 255)
WT = (255, 255, 255, 255)
TR = (0, 0, 0, 0)

# Helper to draw matrix
def mat_to_img(mat, scale=3, target_sz=(64, 64)):
    h = len(mat)
    w = len(mat[0])
    img = Image.new('RGBA', (w * scale, h * scale), TR)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        for x in range(w):
            c = mat[y][x]
            if len(c) == 4 and c[3] > 0:
                draw.rectangle([x*scale, y*scale, (x+1)*scale-1, (y+1)*scale-1], fill=c)
                
    # Center in target_sz
    canvas = Image.new('RGBA', target_sz, TR)
    off_x = (target_sz[0] - img.width) // 2
    off_y = (target_sz[1] - img.height) // 2
    canvas.paste(img, (off_x, off_y), img)
    return canvas

def save_sprite_set(skin_name, part_name, dirs_frames, target_sz=(64, 64)):
    for dest in [base_out, web_out]:
        skin_dir = os.path.join(dest, skin_name)
        os.makedirs(skin_dir, exist_ok=True)
        for dname, flist in dirs_frames.items():
            imgs = []
            for idx, mat in enumerate(flist):
                img = mat_to_img(mat, scale=3, target_sz=target_sz)
                fname = f'{part_name}_{dname}_{idx}.png'
                img.save(os.path.join(skin_dir, fname), 'PNG')
                imgs.append(img)
            # Save GIF
            gif_name = f'{part_name}_{dname}.gif'
            imgs[0].save(os.path.join(skin_dir, gif_name), save_all=True, append_images=imgs[1:], duration=180, loop=0, disposal=2)
    print(f'✅ {skin_name}/{part_name} saved in 4 directions!')


# ====================================================================
# 1. 🐱 KUCING GUDANG (CAT) - Mother (Induk) & Kitten (Anak)
# ====================================================================
O1 = (245, 135, 35, 255); O2 = (210, 95, 15, 255); O3 = (255, 180, 80, 255)
W1 = (255, 250, 240, 255); W2 = (225, 215, 200, 255); PK = (255, 140, 165, 255)
EY = (35, 185, 90, 255); EP = (10, 30, 15, 255)

def get_cat_mother(dname, f):
    bob = 1 if f in [1, 3] else 0
    if dname in ['right', 'left']:
        grid = [[TR for _ in range(22)] for _ in range(18)]
        # Tail
        ty_off = 0 if f % 2 == 0 else 1
        for tx in range(1, 4): grid[5+ty_off][tx] = O1; grid[5+ty_off][tx-1] = BK; grid[5+ty_off][tx+1] = BK
        grid[4+ty_off][3] = O1; grid[4+ty_off][2] = BK; grid[4+ty_off][4] = BK
        # Body
        for y in range(6+bob, 13+bob):
            for x in range(3, 14): grid[y][x] = O1
        for y in range(6+bob, 12+bob): grid[y][6] = O2; grid[y][10] = O2
        for x in range(5, 12): grid[12+bob][x] = W1
        for x in range(3, 14): grid[5+bob][x] = BK; grid[13+bob][x] = BK
        for y in range(6+bob, 13+bob): grid[y][2] = BK; grid[y][14] = BK
        # Head
        for y in range(3+bob, 11+bob):
            for x in range(11, 19): grid[y][x] = O1
        # Ears
        grid[1+bob][12] = BK; grid[2+bob][12] = PK; grid[2+bob][11] = BK; grid[2+bob][13] = BK
        grid[1+bob][16] = BK; grid[2+bob][16] = PK; grid[2+bob][15] = BK; grid[2+bob][17] = BK
        # Eye
        grid[6+bob][16] = EY; grid[6+bob][17] = EP; grid[5+bob][16] = BK; grid[7+bob][16] = BK; grid[6+bob][18] = BK
        # Muzzle & Nose
        grid[7+bob][18] = PK; grid[8+bob][16] = W1; grid[8+bob][17] = W1; grid[8+bob][18] = W1; grid[8+bob][19] = BK
        for y in range(3+bob, 11+bob): grid[y][10] = BK; grid[y][19] = BK
        for x in range(11, 19): grid[2+bob][x] = BK; grid[11+bob][x] = BK
        # Paws Alternating
        if f == 0:
            for y in range(13, 17): grid[y][4] = O2; grid[y][3] = BK; grid[y][5] = BK # Rear-R
            grid[16][4] = W2
            for y in range(13, 17): grid[y][7] = O1; grid[y][6] = BK; grid[y][8] = BK # Rear-L
            grid[16][7] = W1
            for y in range(13, 17): grid[y][11] = O2; grid[y][10] = BK; grid[y][12] = BK # Front-R
            grid[16][11] = W2
            for y in range(13, 16): grid[y][14] = O1; grid[y][13] = BK; grid[y][15] = BK # Front-L forward reach
            grid[15][15] = W1; grid[15][16] = BK; grid[16][14] = BK; grid[16][15] = BK
        elif f == 1:
            for y in range(14, 18):
                grid[y][5] = O2; grid[y][4] = BK; grid[y][6] = BK; grid[17][5] = W2
                grid[y][8] = O1; grid[y][7] = BK; grid[y][9] = BK; grid[17][8] = W1
                grid[y][12] = O2; grid[y][11] = BK; grid[y][13] = BK; grid[17][12] = W2
                grid[y][15] = O1; grid[y][14] = BK; grid[y][16] = BK; grid[17][15] = W1
        elif f == 2:
            for y in range(13, 17): grid[y][4] = O1; grid[y][3] = BK; grid[y][5] = BK
            grid[16][4] = W1
            for y in range(13, 17): grid[y][7] = O2; grid[y][6] = BK; grid[y][8] = BK
            grid[16][7] = W2
            for y in range(13, 17): grid[y][11] = O1; grid[y][10] = BK; grid[y][12] = BK
            grid[16][11] = W1
            for y in range(13, 16): grid[y][14] = O2; grid[y][13] = BK; grid[y][15] = BK
            grid[15][15] = W2; grid[15][16] = BK; grid[16][14] = BK; grid[16][15] = BK
        else: # f == 3
            for y in range(14, 18):
                grid[y][5] = O1; grid[y][4] = BK; grid[y][6] = BK; grid[17][5] = W1
                grid[y][8] = O2; grid[y][7] = BK; grid[y][9] = BK; grid[17][8] = W2
                grid[y][12] = O1; grid[y][11] = BK; grid[y][13] = BK; grid[17][12] = W1
                grid[y][15] = O2; grid[y][14] = BK; grid[y][16] = BK; grid[17][15] = W2
        if dname == 'left':
            grid = [row[::-1] for row in grid]
        return grid
    elif dname == 'down':
        grid = [[TR for _ in range(18)] for _ in range(18)]
        # Tail
        tx = 5 if f in [0, 1] else 12
        for ty in range(2, 6): grid[ty][tx] = O1; grid[ty][tx-1] = BK; grid[ty][tx+1] = BK
        # Body behind
        for y in range(7+bob, 14+bob):
            for x in range(4, 14): grid[y][x] = O1
        # Head
        for y in range(3+bob, 12+bob):
            for x in range(3, 15): grid[y][x] = O1
        grid[1+bob][4] = BK; grid[2+bob][4] = PK; grid[2+bob][3] = BK; grid[2+bob][5] = BK
        grid[1+bob][13] = BK; grid[2+bob][13] = PK; grid[2+bob][12] = BK; grid[2+bob][14] = BK
        # Eyes
        grid[6+bob][5] = EY; grid[6+bob][6] = EP; grid[5+bob][5] = BK; grid[7+bob][5] = BK; grid[6+bob][4] = BK
        grid[6+bob][11] = EP; grid[6+bob][12] = EY; grid[5+bob][12] = BK; grid[7+bob][12] = BK; grid[6+bob][13] = BK
        # Nose & Muzzle
        grid[7+bob][8] = PK; grid[7+bob][9] = PK
        for x in range(7, 11): grid[8+bob][x] = W1; grid[9+bob][x] = W1
        for y in range(3+bob, 12+bob): grid[y][2] = BK; grid[y][15] = BK
        for x in range(3, 15): grid[2+bob][x] = BK; grid[12+bob][x] = BK
        # Paws
        if f == 0:
            for y in range(13, 17): grid[y][4] = W1; grid[y][3] = BK; grid[y][5] = BK
            for y in range(12, 16): grid[y][12] = W2; grid[y][11] = BK; grid[y][13] = BK
        elif f == 1:
            for y in range(13, 17):
                grid[y][4] = W1; grid[y][3] = BK; grid[y][5] = BK
                grid[y][12] = W1; grid[y][11] = BK; grid[y][13] = BK
        elif f == 2:
            for y in range(12, 16): grid[y][4] = W2; grid[y][3] = BK; grid[y][5] = BK
            for y in range(13, 17): grid[y][12] = W1; grid[y][11] = BK; grid[y][13] = BK
        else:
            for y in range(13, 17):
                grid[y][4] = W1; grid[y][3] = BK; grid[y][5] = BK
                grid[y][12] = W1; grid[y][11] = BK; grid[y][13] = BK
        return grid
    else: # up
        grid = [[TR for _ in range(18)] for _ in range(18)]
        tx = 7 if f in [0, 1] else 10
        for ty in range(4, 11): grid[ty][tx] = O1; grid[ty][tx-1] = BK; grid[ty][tx+1] = BK
        for y in range(7+bob, 14+bob):
            for x in range(4, 14): grid[y][x] = O1
        for y in range(3+bob, 11+bob):
            for x in range(3, 15): grid[y][x] = O1
        grid[1+bob][4] = BK; grid[2+bob][4] = O2; grid[2+bob][3] = BK; grid[2+bob][5] = BK
        grid[1+bob][13] = BK; grid[2+bob][13] = O2; grid[2+bob][12] = BK; grid[2+bob][14] = BK
        for y in range(3+bob, 11+bob): grid[y][2] = BK; grid[y][15] = BK
        for x in range(3, 15): grid[2+bob][x] = BK
        # Rear paws
        if f == 0:
            for y in range(13, 16): grid[y][4] = W1; grid[y][3] = BK; grid[y][5] = BK
            for y in range(14, 18): grid[y][12] = W2; grid[y][11] = BK; grid[y][13] = BK
        elif f == 1:
            for y in range(14, 18):
                grid[y][4] = W1; grid[y][3] = BK; grid[y][5] = BK
                grid[y][12] = W1; grid[y][11] = BK; grid[y][13] = BK
        elif f == 2:
            for y in range(14, 18): grid[y][4] = W2; grid[y][3] = BK; grid[y][5] = BK
            for y in range(13, 16): grid[y][12] = W1; grid[y][11] = BK; grid[y][13] = BK
        else:
            for y in range(14, 18):
                grid[y][4] = W1; grid[y][3] = BK; grid[y][5] = BK
                grid[y][12] = W1; grid[y][11] = BK; grid[y][13] = BK
        return grid

cat_mother_dirs = {d: [get_cat_mother(d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
save_sprite_set('cat', 'mother', cat_mother_dirs, target_sz=(64, 64))
save_sprite_set('cat', 'baby', cat_mother_dirs, target_sz=(48, 48))


# ====================================================================
# 2. 🐔 AYAM PETERNAK (CHICKEN) - Mother Hen & Baby Chick (🐥)
# ====================================================================
CW = (250, 250, 250, 255); CS = (220, 220, 230, 255); CR = (235, 45, 45, 255)
CY = (245, 165, 35, 255); CE = (20, 20, 30, 255)
# Chicks yellow
CK1 = (255, 215, 0, 255); CK2 = (235, 180, 0, 255)

def get_chicken_mother(dname, f):
    bob = 1 if f in [1, 3] else 0
    if dname in ['right', 'left']:
        grid = [[TR for _ in range(20)] for _ in range(18)]
        # Comb Red
        grid[1+bob][12] = CR; grid[1+bob][13] = CR; grid[0+bob][12] = BK; grid[0+bob][13] = BK
        grid[2+bob][11] = CR; grid[2+bob][12] = CR; grid[2+bob][13] = CR
        # Head & Body White
        for y in range(3+bob, 12+bob):
            for x in range(4, 15): grid[y][x] = CW
        # Wing
        for y in range(7+bob, 11+bob):
            for x in range(6, 11): grid[y][x] = CS
        grid[8+bob][5] = CS
        # Beak & Wattle
        grid[5+bob][15] = CY; grid[6+bob][15] = CY; grid[5+bob][16] = CY; grid[5+bob][17] = BK
        grid[7+bob][14] = CR; grid[8+bob][14] = CR; grid[9+bob][14] = BK
        # Eye
        grid[4+bob][13] = CE; grid[3+bob][13] = BK; grid[5+bob][13] = BK; grid[4+bob][14] = BK
        # Outlines
        for x in range(4, 15): grid[2+bob][x] = BK; grid[12+bob][x] = BK
        for y in range(3+bob, 12+bob): grid[y][3] = BK; grid[y][15] = BK
        # Legs Alternating
        if f == 0:
            for y in range(12, 17): grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
            grid[16][7] = CY; grid[16][8] = BK # forward foot
            for y in range(12, 16): grid[y][10] = CY; grid[y][9] = BK; grid[y][11] = BK
        elif f == 1:
            for y in range(13, 17):
                grid[y][7] = CY; grid[y][6] = BK; grid[y][8] = BK
                grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        elif f == 2:
            for y in range(12, 16): grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
            for y in range(12, 17): grid[y][10] = CY; grid[y][9] = BK; grid[y][11] = BK
            grid[16][11] = CY; grid[16][12] = BK # forward foot
        else:
            for y in range(13, 17):
                grid[y][7] = CY; grid[y][6] = BK; grid[y][8] = BK
                grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        if dname == 'left': grid = [row[::-1] for row in grid]
        return grid
    elif dname == 'down':
        grid = [[TR for _ in range(18)] for _ in range(18)]
        # Red comb top
        grid[1+bob][8] = CR; grid[1+bob][9] = CR; grid[0+bob][8] = BK; grid[0+bob][9] = BK
        for y in range(3+bob, 12+bob):
            for x in range(4, 14): grid[y][x] = CW
        # Eyes
        grid[5+bob][5] = CE; grid[4+bob][5] = BK; grid[6+bob][5] = BK
        grid[5+bob][12] = CE; grid[4+bob][12] = BK; grid[6+bob][12] = BK
        # Beak & Wattle
        grid[6+bob][8] = CY; grid[6+bob][9] = CY; grid[7+bob][8] = CY; grid[7+bob][9] = CY
        grid[8+bob][8] = CR; grid[8+bob][9] = CR; grid[9+bob][8] = BK; grid[9+bob][9] = BK
        for x in range(4, 14): grid[2+bob][x] = BK; grid[12+bob][x] = BK
        for y in range(3+bob, 12+bob): grid[y][3] = BK; grid[y][14] = BK
        # Feet
        if f == 0:
            for y in range(12, 17): grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
            for y in range(12, 15): grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        elif f == 1:
            for y in range(13, 17):
                grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
                grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        elif f == 2:
            for y in range(12, 15): grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
            for y in range(12, 17): grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        else:
            for y in range(13, 17):
                grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
                grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        return grid
    else: # up
        grid = [[TR for _ in range(18)] for _ in range(18)]
        grid[1+bob][8] = CR; grid[1+bob][9] = CR; grid[0+bob][8] = BK; grid[0+bob][9] = BK
        for y in range(3+bob, 12+bob):
            for x in range(4, 14): grid[y][x] = CW
        # Tail feathers
        for y in range(4+bob, 8+bob): grid[y][8] = CS; grid[y][9] = CS
        for x in range(4, 14): grid[2+bob][x] = BK; grid[12+bob][x] = BK
        for y in range(3+bob, 12+bob): grid[y][3] = BK; grid[y][14] = BK
        if f == 0:
            for y in range(12, 16): grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
            for y in range(13, 17): grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        elif f == 1:
            for y in range(13, 17):
                grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
                grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        elif f == 2:
            for y in range(13, 17): grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
            for y in range(12, 16): grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        else:
            for y in range(13, 17):
                grid[y][6] = CY; grid[y][5] = BK; grid[y][7] = BK
                grid[y][11] = CY; grid[y][10] = BK; grid[y][12] = BK
        return grid

# Chick (Baby)
def get_chick(dname, f):
    bob = 1 if f in [1, 3] else 0
    grid = [[TR for _ in range(14)] for _ in range(14)]
    if dname in ['right', 'left']:
        for y in range(2+bob, 9+bob):
            for x in range(2, 10): grid[y][x] = CK1
        grid[4+bob][8] = CE; grid[3+bob][8] = BK; grid[5+bob][8] = BK
        grid[5+bob][10] = CY; grid[5+bob][11] = CY; grid[5+bob][12] = BK
        for x in range(2, 10): grid[1+bob][x] = BK; grid[9+bob][x] = BK
        for y in range(2+bob, 9+bob): grid[y][1] = BK; grid[y][10] = BK
        # Legs
        if f % 2 == 0:
            grid[10][4] = CY; grid[11][4] = CY; grid[10][7] = CY; grid[11][8] = CY
        else:
            grid[10][5] = CY; grid[11][6] = CY; grid[10][7] = CY; grid[11][7] = CY
        if dname == 'left': grid = [row[::-1] for row in grid]
    else: # down or up
        for y in range(2+bob, 9+bob):
            for x in range(2, 12): grid[y][x] = CK1
        if dname == 'down':
            grid[4+bob][4] = CE; grid[4+bob][9] = CE
            grid[5+bob][6] = CY; grid[5+bob][7] = CY
        for x in range(2, 12): grid[1+bob][x] = BK; grid[9+bob][x] = BK
        for y in range(2+bob, 9+bob): grid[y][1] = BK; grid[y][12] = BK
        if f % 2 == 0:
            grid[10][4] = CY; grid[11][4] = CY; grid[10][9] = CY; grid[11][9] = CY
        else:
            grid[10][5] = CY; grid[11][5] = CY; grid[10][8] = CY; grid[11][8] = CY
    return grid

chicken_mother_dirs = {d: [get_chicken_mother(d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
chicken_baby_dirs = {d: [get_chick(d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
save_sprite_set('chicken', 'mother', chicken_mother_dirs, target_sz=(64, 64))
save_sprite_set('chicken', 'baby', chicken_baby_dirs, target_sz=(44, 44))


# ====================================================================
# 3. 🐜 SEMUT PEKERJA SEGARI (ANT) - Mother (Worker Ant) & Baby Ants
# ====================================================================
AB1 = (45, 30, 25, 255); AB2 = (75, 50, 40, 255); AR = (185, 75, 45, 255)

def get_ant(role, dname, f):
    bob = 1 if f in [1, 3] else 0
    grid = [[TR for _ in range(20)] for _ in range(18)]
    if dname in ['right', 'left']:
        # Head with Antennae
        grid[1+bob][16] = BK; grid[2+bob][15] = BK; grid[3+bob][14] = BK
        grid[1+bob][18] = BK; grid[2+bob][17] = BK
        for y in range(4+bob, 9+bob):
            for x in range(12, 17): grid[y][x] = AB1
        grid[5+bob][15] = WT; grid[5+bob][16] = BK # eye
        # Thorax (middle)
        for y in range(5+bob, 9+bob):
            for x in range(8, 12): grid[y][x] = AR
        # Abdomen (large oval back)
        for y in range(4+bob, 10+bob):
            for x in range(2, 8): grid[y][x] = AB1
        grid[5+bob][4] = AB2; grid[6+bob][4] = AB2
        # Outlines
        for y in range(4+bob, 10+bob): grid[y][1] = BK; grid[y][8] = BK; grid[y][12] = BK; grid[y][17] = BK
        for x in range(2, 8): grid[3+bob][x] = BK; grid[10+bob][x] = BK
        for x in range(12, 17): grid[3+bob][x] = BK; grid[9+bob][x] = BK
        # 6 Legs Alternating
        if f == 0:
            grid[9+bob][4] = BK; grid[10+bob][3] = BK; grid[11+bob][2] = BK
            grid[9+bob][9] = BK; grid[10+bob][10] = BK; grid[11+bob][11] = BK
            grid[9+bob][14] = BK; grid[10+bob][15] = BK; grid[11+bob][16] = BK
        elif f == 1:
            grid[10+bob][4] = BK; grid[11+bob][4] = BK
            grid[10+bob][9] = BK; grid[11+bob][9] = BK
            grid[10+bob][14] = BK; grid[11+bob][14] = BK
        elif f == 2:
            grid[9+bob][4] = BK; grid[10+bob][5] = BK; grid[11+bob][6] = BK
            grid[9+bob][9] = BK; grid[10+bob][8] = BK; grid[11+bob][7] = BK
            grid[9+bob][14] = BK; grid[10+bob][13] = BK; grid[11+bob][12] = BK
        else:
            grid[10+bob][4] = BK; grid[11+bob][4] = BK
            grid[10+bob][9] = BK; grid[11+bob][9] = BK
            grid[10+bob][14] = BK; grid[11+bob][14] = BK
        if dname == 'left': grid = [row[::-1] for row in grid]
    else: # down / up
        for y in range(4+bob, 8+bob):
            for x in range(7, 13): grid[y][x] = AB1 # Head
        for y in range(8+bob, 11+bob):
            for x in range(8, 12): grid[y][x] = AR # Thorax
        for y in range(11+bob, 16+bob):
            for x in range(6, 14): grid[y][x] = AB1 # Abdomen
        # Antennae
        grid[1+bob][6] = BK; grid[2+bob][7] = BK; grid[3+bob][8] = BK
        grid[1+bob][13] = BK; grid[2+bob][12] = BK; grid[3+bob][11] = BK
        # Eyes
        if dname == 'down':
            grid[5+bob][8] = WT; grid[5+bob][9] = BK
            grid[5+bob][11] = WT; grid[5+bob][12] = BK
        # Legs left/right
        if f % 2 == 0:
            grid[8+bob][5] = BK; grid[9+bob][4] = BK; grid[8+bob][14] = BK; grid[9+bob][15] = BK
            grid[11+bob][4] = BK; grid[12+bob][3] = BK; grid[11+bob][15] = BK; grid[12+bob][16] = BK
        else:
            grid[9+bob][5] = BK; grid[10+bob][4] = BK; grid[9+bob][14] = BK; grid[10+bob][15] = BK
            grid[12+bob][4] = BK; grid[13+bob][3] = BK; grid[12+bob][15] = BK; grid[13+bob][16] = BK
    return grid

ant_mother_dirs = {d: [get_ant('mother', d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
ant_baby_dirs = {d: [get_ant('baby', d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
save_sprite_set('ant', 'mother', ant_mother_dirs, target_sz=(64, 64))
save_sprite_set('ant', 'baby', ant_baby_dirs, target_sz=(44, 44))


# ====================================================================
# 4. 🐛 ULAT SAYUR (CATERPILLAR) - 3 Connected Parts: Head, Body, Tail
# ====================================================================
UG1 = (130, 205, 30, 255); UG2 = (180, 240, 70, 255); UG3 = (80, 140, 15, 255)
UY  = (250, 220, 50, 255); UPK = (255, 130, 160, 255)

def get_caterpillar_part(part, dname, f):
    bob = 1 if f in [1, 3] else 0
    grid = [[TR for _ in range(20)] for _ in range(18)]
    
    if dname in ['right', 'left']:
        if part == 'head':
            # Antennae
            grid[1+bob][15] = UPK; grid[2+bob][14] = UG1; grid[3+bob][13] = BK
            # Head circle
            for y in range(4+bob, 13+bob):
                for x in range(7, 17): grid[y][x] = UG1
            grid[5+bob][10] = UG2; grid[6+bob][10] = UG2 # highlight
            # Eye
            grid[6+bob][14] = BK; grid[6+bob][15] = WT; grid[7+bob][14] = BK; grid[7+bob][15] = BK
            grid[8+bob][14] = UPK # blush
            for x in range(7, 17): grid[3+bob][x] = BK; grid[13+bob][x] = BK
            for y in range(4+bob, 13+bob): grid[y][17] = BK
            # Connecting flat edge on left (x=7)
            # Legs
            grid[14+bob][10] = UY; grid[14+bob][14] = UY
        elif part == 'body':
            # Seamless body segment connecting seamlessly from left (x=0) to right (x=19)
            for y in range(5+bob, 13+bob):
                for x in range(0, 20): grid[y][x] = UG1
            for x in range(0, 20): grid[6+bob][x] = UG2
            grid[8+bob][8] = UY; grid[8+bob][9] = UY; grid[9+bob][8] = UY; grid[9+bob][9] = UY # spot
            for x in range(0, 20): grid[4+bob][x] = BK; grid[13+bob][x] = BK
            # Segment dividers
            grid[6+bob][10] = UG3; grid[7+bob][10] = UG3; grid[8+bob][10] = UG3
            # Feet
            grid[14+bob][5] = UY; grid[14+bob][15] = UY
        else: # tail
            # Tapered tail end with leaf tip
            for y in range(5+bob, 13+bob):
                for x in range(6, 20): grid[y][x] = UG1
            for y in range(7+bob, 11+bob):
                for x in range(2, 7): grid[y][x] = UG2 # leaf tip
            grid[8+bob][1] = BK; grid[9+bob][1] = BK
            for x in range(6, 20): grid[4+bob][x] = BK; grid[13+bob][x] = BK
            for x in range(2, 7): grid[6+bob][x] = BK; grid[11+bob][x] = BK
            grid[14+bob][12] = UY
        if dname == 'left': grid = [row[::-1] for row in grid]
    else: # down / up
        # Vertical connected segments
        for y in range(0, 18):
            for x in range(5, 15): grid[y][x] = UG1
        for y in range(0, 18): grid[y][4] = BK; grid[y][15] = BK
        if part == 'head':
            if dname == 'down':
                # Head at bottom
                grid[13+bob][7] = BK; grid[13+bob][12] = BK # eyes
                grid[16+bob][5] = UPK; grid[16+bob][14] = UPK # antennae tips
                for x in range(5, 15): grid[15+bob][x] = BK
            else:
                for x in range(5, 15): grid[2+bob][x] = BK
        elif part == 'tail':
            if dname == 'down':
                for x in range(5, 15): grid[1+bob][x] = BK
            else:
                for x in range(5, 15): grid[16+bob][x] = BK
    return grid

for part in ['head', 'body', 'tail']:
    pdirs = {d: [get_caterpillar_part(part, d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
    save_sprite_set('caterpillar', part, pdirs, target_sz=(64, 64))


# ====================================================================
# 5. 🐟 IKAN LELE SEGARI (FISH) - 3 Connected Parts: Head, Body, Tail
# ====================================================================
FC1 = (6, 182, 212, 255); FC2 = (103, 232, 249, 255); FC3 = (14, 116, 144, 255)
FT = (165, 243, 252, 255); FY = (250, 204, 21, 255)

def get_fish_part(part, dname, f):
    bob = 1 if f in [1, 3] else 0
    grid = [[TR for _ in range(22)] for _ in range(18)]
    
    if dname in ['right', 'left']:
        if part == 'head':
            # Whiskers
            grid[5+bob][18] = FT; grid[4+bob][19] = FT; grid[3+bob][20] = FT
            grid[10+bob][18] = FT; grid[11+bob][19] = FT; grid[12+bob][20] = FT
            # Head
            for y in range(4+bob, 13+bob):
                for x in range(6, 18): grid[y][x] = FC1
            for x in range(8, 16): grid[5+bob][x] = FC2 # highlight
            # Eye
            grid[6+bob][14] = BK; grid[6+bob][15] = WT; grid[7+bob][14] = BK; grid[7+bob][15] = BK
            # Outline
            for x in range(6, 18): grid[3+bob][x] = BK; grid[13+bob][x] = BK
            for y in range(4+bob, 13+bob): grid[y][18] = BK
        elif part == 'body':
            # Dorsal Fin
            grid[2+bob][9] = FC2; grid[2+bob][10] = FC2; grid[1+bob][9] = BK; grid[1+bob][10] = BK
            grid[3+bob][8] = FC2; grid[3+bob][9] = FC2; grid[3+bob][10] = FC2; grid[3+bob][11] = FC2
            # Seamless body tube
            for y in range(4+bob, 13+bob):
                for x in range(0, 22): grid[y][x] = FC1
            for x in range(0, 22): grid[5+bob][x] = FC2
            for x in range(0, 22): grid[12+bob][x] = FC3
            for x in range(0, 22): grid[3+bob][x] = BK; grid[13+bob][x] = BK
        else: # tail (caudal fin)
            # Tapered tail with fin
            fin_wag = 1 if f in [0, 1] else -1
            for y in range(5+bob, 12+bob):
                for x in range(8, 22): grid[y][x] = FC1
            # Caudal fin lobes
            for y in range(2+bob+fin_wag, 6+bob+fin_wag):
                for x in range(2, 9): grid[y][x] = FC2
            for y in range(11+bob+fin_wag, 15+bob+fin_wag):
                for x in range(2, 9): grid[y][x] = FC2
            grid[3+bob+fin_wag][1] = BK; grid[13+bob+fin_wag][1] = BK
            for x in range(8, 22): grid[4+bob][x] = BK; grid[12+bob][x] = BK
        if dname == 'left': grid = [row[::-1] for row in grid]
    else: # down / up
        for y in range(0, 18):
            for x in range(5, 15): grid[y][x] = FC1
        for y in range(0, 18): grid[y][4] = BK; grid[y][15] = BK
        if part == 'head':
            if dname == 'down':
                grid[13+bob][7] = BK; grid[13+bob][12] = BK
                grid[16+bob][5] = FT; grid[16+bob][14] = FT
                for x in range(5, 15): grid[15+bob][x] = BK
            else:
                for x in range(5, 15): grid[2+bob][x] = BK
        elif part == 'tail':
            if dname == 'down':
                for x in range(5, 15): grid[1+bob][x] = BK
            else:
                for x in range(5, 15): grid[16+bob][x] = BK
    return grid

for part in ['head', 'body', 'tail']:
    pdirs = {d: [get_fish_part(part, d, f) for f in range(4)] for d in ['right', 'left', 'down', 'up']}
    save_sprite_set('catfish', part, pdirs, target_sz=(64, 64))

print('🎉 ALL 5 MASCOT CHARACTER SETS GENERATED IN FULL 16-BIT CHIBI STYLE!')
