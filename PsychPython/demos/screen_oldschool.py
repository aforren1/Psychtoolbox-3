from psychtoolbox import Screen
from time import sleep
import numpy as np

if __name__ == '__main__':
    screens = Screen('Screens')
    screen_number = max(screens)
    # the splash screen doesn't look right, so disable for now
    Screen('Preference', 'VisualDebuglevel', 3)
    w, rect = Screen('OpenWindow', screen_number,
                     [80.0]*4, [0., 0., 800, 800])

    Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA')
    fps = Screen('FrameRate', w)
    if fps == 0:
        fps = 1 / Screen('GetFlipInterval', w)
    print(fps)

    colors = np.array([[255., 0., 0., 128.],
                       [0., 255., 0., 128.]]).T

    locs = np.array([[200., 200., 400., 400.],
                     [300., 300., 500., 500.]]).T
    Screen('FillRect', w, colors, locs)
    Screen('Flip', w)
    for i in range(255):
        colors[0, 1] = i
        colors[1, 0] = i
        locs[0, 1] += 1
        locs[2, 0] += 1
        locs[0, 0] += 1
        locs[2, 1] += 1
        Screen('FillRect', w, colors, locs)
        Screen('Flip', w)

    Screen('Close', w)
