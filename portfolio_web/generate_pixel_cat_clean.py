import os
from PIL import Image, ImageDraw

out_dir = r'c:\Users\MyBook Hype AMD\KULIAH SISTEM INFORMASI\project apa aja\hitung_gaji_segari\portfolio_web\sprites\chibi_cat'
os.makedirs(out_dir, exist_ok=True)

# Color Palette (RGBA tuples):
BK = (20, 20, 25, 255)       # Outline Black
O1 = (245, 135, 35, 255)     # Orange Base
O2 = (210, 95, 15, 255)      # Dark Orange Stripe
O3 = (255, 180, 80, 255)     # Light Orange Highlight
W1 = (255, 250, 240, 255)    # White Muzzle & Paws
W2 = (225, 215, 200, 255)    # Shaded White
PK = (255, 140, 165, 255)    # Pink Inner Ear / Nose
EY = (35, 185, 90, 255)      # Emerald Eye
EP = (10, 30, 15, 255)       # Eye Pupil
TR = (0, 0, 0, 0)            # Transparent

# ----------------------------------------------------
# 1. SIDE VIEW WALK RIGHT (4 FRAMES: Alternating Legs)
# Width 24, Height 20
# ----------------------------------------------------
def get_side_cat(frame):
    grid = [[TR for _ in range(24)] for _ in range(20)]
    bob = 1 if frame in [1, 3] else 0
    
    # Tail
    tail_pts = [
        [(2,7+bob), (1,6+bob), (1,5+bob), (2,4+bob), (3,4+bob)],
        [(2,8+bob), (1,7+bob), (1,6+bob), (2,5+bob), (3,5+bob)],
        [(2,7+bob), (1,6+bob), (2,5+bob), (3,4+bob), (4,4+bob)],
        [(2,8+bob), (1,7+bob), (1,6+bob), (2,5+bob), (3,5+bob)],
    ][frame]
    
    for tx, ty in tail_pts:
        grid[ty][tx] = O1
        if ty > 0: grid[ty-1][tx] = O3
        if tx > 0: grid[ty][tx-1] = BK
        if tx < 23: grid[ty][tx+1] = BK

    # Body
    for y in range(8 + bob, 15 + bob):
        for x in range(4, 16):
            grid[y][x] = O1
    
    # Stripes
    for x in range(4, 16):
        grid[8+bob][x] = O3
    for y in range(8 + bob, 14 + bob):
        grid[y][7] = O2
        grid[y][11] = O2
    
    # Belly White
    for x in range(7, 13):
        grid[14+bob][x] = W1
        
    # Body Outline
    for x in range(4, 16):
        grid[7+bob][x] = BK
        grid[15+bob][x] = BK
    for y in range(8+bob, 15+bob):
        grid[y][3] = BK
        grid[y][16] = BK

    # Head
    for y in range(4 + bob, 13 + bob):
        for x in range(13, 21):
            grid[y][x] = O1
    for x in range(13, 21):
        grid[4+bob][x] = O3
    
    # Ears
    grid[1+bob][14] = BK
    grid[2+bob][13] = BK; grid[2+bob][14] = PK; grid[2+bob][15] = BK
    grid[3+bob][13] = BK; grid[3+bob][14] = PK; grid[3+bob][15] = O1; grid[3+bob][16] = BK
    grid[1+bob][18] = BK
    grid[2+bob][17] = BK; grid[2+bob][18] = PK; grid[2+bob][19] = BK
    grid[3+bob][17] = BK; grid[3+bob][18] = PK; grid[3+bob][19] = O1; grid[3+bob][20] = BK
    
    # Eye
    grid[7+bob][18] = EY; grid[7+bob][19] = EP
    grid[8+bob][18] = EY; grid[8+bob][19] = EP
    grid[6+bob][18] = BK; grid[6+bob][19] = BK
    grid[9+bob][18] = BK; grid[9+bob][19] = BK
    grid[7+bob][17] = BK; grid[8+bob][17] = BK
    grid[7+bob][20] = BK; grid[8+bob][20] = BK
    
    # Muzzle
    grid[9+bob][20] = PK; grid[9+bob][21] = BK
    for y in range(10+bob, 12+bob):
        for x in range(18, 21): grid[y][x] = W1
        grid[y][21] = BK
    
    # Head Outline
    grid[3+bob][14] = BK; grid[3+bob][15] = BK; grid[3+bob][16] = BK
    for y in range(4+bob, 13+bob):
        grid[y][12] = BK
        grid[y][21] = BK
    for x in range(13, 21):
        grid[13+bob][x] = BK

    # LEGS (Alternating 4-Paw Quadruped Walking Cycle)
    if frame == 0:
        # Rear-Right back
        for y in range(14, 18): grid[y][4] = BK; grid[y][5] = O2; grid[y][6] = BK
        grid[18][4] = BK; grid[18][5] = W2; grid[18][6] = BK
        # Rear-Left plant
        for y in range(14, 18): grid[y][7] = BK; grid[y][8] = O1; grid[y][9] = BK
        grid[18][7] = BK; grid[18][8] = W1; grid[18][9] = BK
        # Front-Right plant
        for y in range(14, 18): grid[y][12] = BK; grid[y][13] = O2; grid[y][14] = BK
        grid[18][12] = BK; grid[18][13] = W2; grid[18][14] = BK
        # Front-Left reach forward!
        for y in range(14, 17): grid[y][16] = BK; grid[y][17] = O1; grid[y][18] = BK
        grid[17][17] = BK; grid[17][18] = W1; grid[17][19] = BK; grid[18][17] = BK; grid[18][18] = BK
    elif frame == 1:
        # All plant / pass
        for y in range(15, 19): grid[y][5] = BK; grid[y][6] = O2; grid[y][7] = BK
        grid[19][5] = BK; grid[19][6] = W2; grid[19][7] = BK
        for y in range(15, 19): grid[y][8] = BK; grid[y][9] = O1; grid[y][10] = BK
        grid[19][8] = BK; grid[19][9] = W1; grid[19][10] = BK
        for y in range(15, 19): grid[y][13] = BK; grid[y][14] = O2; grid[y][15] = BK
        grid[19][13] = BK; grid[19][14] = W2; grid[19][15] = BK
        for y in range(15, 19): grid[y][16] = BK; grid[y][17] = O1; grid[y][18] = BK
        grid[19][16] = BK; grid[19][17] = W1; grid[19][18] = BK
    elif frame == 2:
        # Rear-Left back
        for y in range(14, 18): grid[y][4] = BK; grid[y][5] = O1; grid[y][6] = BK
        grid[18][4] = BK; grid[18][5] = W1; grid[18][6] = BK
        # Rear-Right plant
        for y in range(14, 18): grid[y][7] = BK; grid[y][8] = O2; grid[y][9] = BK
        grid[18][7] = BK; grid[18][8] = W2; grid[18][9] = BK
        # Front-Left plant
        for y in range(14, 18): grid[y][12] = BK; grid[y][13] = O1; grid[y][14] = BK
        grid[18][12] = BK; grid[18][13] = W1; grid[18][14] = BK
        # Front-Right reach forward!
        for y in range(14, 17): grid[y][16] = BK; grid[y][17] = O2; grid[y][18] = BK
        grid[17][17] = BK; grid[17][18] = W2; grid[17][19] = BK; grid[18][17] = BK; grid[18][18] = BK
    elif frame == 3:
        for y in range(15, 19): grid[y][5] = BK; grid[y][6] = O1; grid[y][7] = BK
        grid[19][5] = BK; grid[19][6] = W1; grid[19][7] = BK
        for y in range(15, 19): grid[y][8] = BK; grid[y][9] = O2; grid[y][10] = BK
        grid[19][8] = BK; grid[19][9] = W2; grid[19][10] = BK
        for y in range(15, 19): grid[y][13] = BK; grid[y][14] = O1; grid[y][15] = BK
        grid[19][13] = BK; grid[19][14] = W1; grid[19][15] = BK
        for y in range(15, 19): grid[y][16] = BK; grid[y][17] = O2; grid[y][18] = BK
        grid[19][16] = BK; grid[19][17] = W2; grid[19][18] = BK

    return grid


# ----------------------------------------------------
# 2. FRONT VIEW WALK DOWN (4 FRAMES: Quadruped 3/4 Top-Down)
# Width 22, Height 22
# ----------------------------------------------------
def get_down_cat(frame):
    grid = [[TR for _ in range(22)] for _ in range(22)]
    bob = 1 if frame in [1, 3] else 0
    
    # Tail
    tail_dir = -1 if frame in [0, 1] else 1
    tx = 6 if tail_dir == -1 else 15
    for ty in range(2, 7):
        grid[ty][tx] = O1
        grid[ty][tx-1] = BK; grid[ty][tx+1] = BK
    grid[1][tx] = BK

    # Body behind head
    for y in range(9 + bob, 17 + bob):
        for x in range(5, 17):
            grid[y][x] = O1
    for x in range(5, 17): grid[9+bob][x] = O3
    for y in range(9+bob, 15+bob):
        grid[y][7] = O2; grid[y][14] = O2
    for y in range(9+bob, 17+bob):
        grid[y][4] = BK; grid[y][17] = BK
    for x in range(5, 17):
        grid[17+bob][x] = BK

    # Head
    for y in range(3 + bob, 14 + bob):
        for x in range(4, 18):
            grid[y][x] = O1
    for x in range(5, 17): grid[3+bob][x] = O3
    
    # Ears
    grid[0+bob][5] = BK
    grid[1+bob][4] = BK; grid[1+bob][5] = PK; grid[1+bob][6] = BK
    grid[2+bob][4] = BK; grid[2+bob][5] = PK; grid[2+bob][6] = O1; grid[2+bob][7] = BK
    grid[0+bob][16] = BK
    grid[1+bob][15] = BK; grid[1+bob][16] = PK; grid[1+bob][17] = BK
    grid[2+bob][14] = BK; grid[2+bob][15] = O1; grid[2+bob][16] = PK; grid[2+bob][17] = BK
    
    # Eyes
    grid[7+bob][6] = BK; grid[7+bob][7] = BK; grid[7+bob][8] = BK
    grid[8+bob][6] = BK; grid[8+bob][7] = EY; grid[8+bob][8] = EP; grid[8+bob][9] = BK
    grid[9+bob][6] = BK; grid[9+bob][7] = EY; grid[9+bob][8] = EP; grid[9+bob][9] = BK
    grid[10+bob][6] = BK; grid[10+bob][7] = BK; grid[10+bob][8] = BK
    grid[7+bob][13] = BK; grid[7+bob][14] = BK; grid[7+bob][15] = BK
    grid[8+bob][12] = BK; grid[8+bob][13] = EP; grid[8+bob][14] = EY; grid[8+bob][15] = BK
    grid[9+bob][12] = BK; grid[9+bob][13] = EP; grid[9+bob][14] = EY; grid[9+bob][15] = BK
    grid[10+bob][13] = BK; grid[10+bob][14] = BK; grid[10+bob][15] = BK
    
    # Nose & Muzzle
    grid[9+bob][10] = PK; grid[9+bob][11] = PK
    for y in range(10+bob, 13+bob):
        for x in range(8, 14):
            grid[y][x] = W1
    grid[11+bob][10] = BK; grid[11+bob][11] = BK
    
    # Head Outline
    grid[2+bob][8] = BK; grid[2+bob][9] = BK; grid[2+bob][10] = BK; grid[2+bob][11] = BK; grid[2+bob][12] = BK; grid[2+bob][13] = BK
    for y in range(3+bob, 14+bob):
        grid[y][3] = BK; grid[y][18] = BK
    for x in range(4, 18):
        grid[14+bob][x] = BK

    # Front Paws (Alternating Forward Steps on all 4s)
    if frame == 0:
        # Left paw step forward down
        for y in range(15, 20): grid[y][5] = BK; grid[y][6] = W1; grid[y][7] = W1; grid[y][8] = BK
        grid[20][5] = BK; grid[20][6] = W1; grid[20][7] = W1; grid[20][8] = BK; grid[21][6] = BK; grid[21][7] = BK
        # Right paw plant
        for y in range(15, 19): grid[y][13] = BK; grid[y][14] = W2; grid[y][15] = W2; grid[y][16] = BK
        grid[19][13] = BK; grid[19][14] = W2; grid[19][15] = W2; grid[19][16] = BK
    elif frame == 1:
        for y in range(16, 20):
            grid[y][5] = BK; grid[y][6] = W1; grid[y][7] = W1; grid[y][8] = BK
            grid[y][13] = BK; grid[y][14] = W1; grid[y][15] = W1; grid[y][16] = BK
        grid[20][6] = BK; grid[20][7] = BK; grid[20][14] = BK; grid[20][15] = BK
    elif frame == 2:
        # Left paw plant
        for y in range(15, 19): grid[y][5] = BK; grid[y][6] = W2; grid[y][7] = W2; grid[y][8] = BK
        grid[19][5] = BK; grid[19][6] = W2; grid[19][7] = W2; grid[19][8] = BK
        # Right paw step forward down
        for y in range(15, 20): grid[y][13] = BK; grid[y][14] = W1; grid[y][15] = W1; grid[y][16] = BK
        grid[20][13] = BK; grid[20][14] = W1; grid[20][15] = W1; grid[20][16] = BK; grid[21][14] = BK; grid[21][15] = BK
    elif frame == 3:
        for y in range(16, 20):
            grid[y][5] = BK; grid[y][6] = W1; grid[y][7] = W1; grid[y][8] = BK
            grid[y][13] = BK; grid[y][14] = W1; grid[y][15] = W1; grid[y][16] = BK
        grid[20][6] = BK; grid[20][7] = BK; grid[20][14] = BK; grid[20][15] = BK

    return grid


# ----------------------------------------------------
# 3. BACK VIEW WALK UP (4 FRAMES: Quadruped 3/4 Top-Down Back View)
# Width 22, Height 22
# ----------------------------------------------------
def get_up_cat(frame):
    grid = [[TR for _ in range(22)] for _ in range(22)]
    bob = 1 if frame in [1, 3] else 0
    
    # Tail pointing up & wagging left/right
    tail_dir = -1 if frame in [0, 1] else 1
    tx = 9 if tail_dir == -1 else 12
    for ty in range(6, 14):
        grid[ty][tx] = O1
        grid[ty][tx-1] = BK; grid[ty][tx+1] = BK
    grid[5][tx] = BK

    # Body
    for y in range(9 + bob, 18 + bob):
        for x in range(5, 17):
            grid[y][x] = O1
    for y in range(9+bob, 17+bob):
        grid[y][8] = O2; grid[y][13] = O2
    for y in range(9+bob, 18+bob):
        grid[y][4] = BK; grid[y][17] = BK
    for x in range(5, 17):
        grid[18+bob][x] = BK

    # Head from back
    for y in range(3 + bob, 12 + bob):
        for x in range(4, 18):
            grid[y][x] = O1
    for x in range(5, 17): grid[3+bob][x] = O3
    
    # Back of Ears
    grid[0+bob][5] = BK
    grid[1+bob][4] = BK; grid[1+bob][5] = O2; grid[1+bob][6] = BK
    grid[2+bob][4] = BK; grid[2+bob][5] = O1; grid[2+bob][6] = O1; grid[2+bob][7] = BK
    grid[0+bob][16] = BK
    grid[1+bob][15] = BK; grid[1+bob][16] = O2; grid[1+bob][17] = BK
    grid[2+bob][14] = BK; grid[2+bob][15] = O1; grid[2+bob][16] = O1; grid[2+bob][17] = BK
    
    # Head Stripes
    grid[4+bob][10] = O2; grid[4+bob][11] = O2
    grid[5+bob][10] = O2; grid[5+bob][11] = O2
    
    grid[2+bob][8] = BK; grid[2+bob][9] = BK; grid[2+bob][10] = BK; grid[2+bob][11] = BK; grid[2+bob][12] = BK; grid[2+bob][13] = BK
    for y in range(3+bob, 12+bob):
        grid[y][3] = BK; grid[y][18] = BK

    # Rear Paws (Stepping up)
    if frame == 0:
        for y in range(16, 19): grid[y][5] = BK; grid[y][6] = W1; grid[y][7] = W1; grid[y][8] = BK
        grid[19][6] = BK; grid[19][7] = BK
        for y in range(17, 21): grid[y][13] = BK; grid[y][14] = W2; grid[y][15] = W2; grid[y][16] = BK
        grid[21][14] = BK; grid[21][15] = BK
    elif frame == 1:
        for y in range(17, 21):
            grid[y][5] = BK; grid[y][6] = W1; grid[y][7] = W1; grid[y][8] = BK
            grid[y][13] = BK; grid[y][14] = W1; grid[y][15] = W1; grid[y][16] = BK
        grid[21][6] = BK; grid[21][7] = BK; grid[21][14] = BK; grid[21][15] = BK
    elif frame == 2:
        for y in range(17, 21): grid[y][5] = BK; grid[y][6] = W2; grid[y][7] = W2; grid[y][8] = BK
        grid[21][6] = BK; grid[21][7] = BK
        for y in range(16, 19): grid[y][13] = BK; grid[y][14] = W1; grid[y][15] = W1; grid[y][16] = BK
        grid[19][14] = BK; grid[19][15] = BK
    elif frame == 3:
        for y in range(17, 21):
            grid[y][5] = BK; grid[y][6] = W1; grid[y][7] = W1; grid[y][8] = BK
            grid[y][13] = BK; grid[y][14] = W1; grid[y][15] = W1; grid[y][16] = BK
        grid[21][6] = BK; grid[21][7] = BK; grid[21][14] = BK; grid[21][15] = BK

    return grid


def matrix_to_img(mat, scale=3):
    h = len(mat)
    w = len(mat[0])
    img = Image.new('RGBA', (w * scale, h * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        for x in range(w):
            c = mat[y][x]
            if len(c) == 4 and c[3] > 0:
                draw.rectangle([x*scale, y*scale, (x+1)*scale-1, (y+1)*scale-1], fill=c)
    return img

dirs_frames = {
    'right': [get_side_cat(f) for f in range(4)],
    'down':  [get_down_cat(f) for f in range(4)],
    'up':    [get_up_cat(f) for f in range(4)]
}

# Left is flipped Right
dirs_frames['left'] = []
for f_mat in dirs_frames['right']:
    f_l = [row[::-1] for row in f_mat]
    dirs_frames['left'].append(f_l)

for dname, frames in dirs_frames.items():
    m_imgs = []
    k_imgs = []
    for idx, mat in enumerate(frames):
        # Mother sprite
        m_img = matrix_to_img(mat, scale=3)
        m_sq = Image.new('RGBA', (76, 76), (0,0,0,0))
        m_sq.paste(m_img, ((76 - m_img.width)//2, (76 - m_img.height)//2))
        m_sq.save(os.path.join(out_dir, f'mother_{dname}_{idx}.png'), 'PNG')
        m_imgs.append(m_sq)
        
        # Kitten sprite
        k_img = matrix_to_img(mat, scale=2)
        k_sq = Image.new('RGBA', (52, 52), (0,0,0,0))
        k_sq.paste(k_img, ((52 - k_img.width)//2, (52 - k_img.height)//2))
        k_sq.save(os.path.join(out_dir, f'kitten_{dname}_{idx}.png'), 'PNG')
        k_imgs.append(k_sq)
        
    m_imgs[0].save(os.path.join(out_dir, f'mother_{dname}.gif'), save_all=True, append_images=m_imgs[1:], duration=180, loop=0, disposal=2)
    k_imgs[0].save(os.path.join(out_dir, f'kitten_{dname}.gif'), save_all=True, append_images=k_imgs[1:], duration=180, loop=0, disposal=2)
    print(f'✅ Handcrafted Chibi Cat {dname} successfully generated!')

print('🎉 Complete perfect pixel art generation finished!')
