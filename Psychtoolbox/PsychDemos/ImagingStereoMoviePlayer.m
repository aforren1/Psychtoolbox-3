function ImagingStereoMoviePlayer(moviefile, stereoMode, imaging, anaglyphmode, screenid, hdr, topBottom)
% ImagingStereoMoviePlayer(moviefile [, stereoMode=8][, imaging=1][, anaglyphmode=0][, screenid=max][, hdr=0][, topBottom=0])
%
% Minimalistic movie player for stereo movies. Reads movie from file
% 'moviefile'. Left half of each movie video frame must contain left-eye
% image, whereas right half of each frame must contain right-eye image.
%
% 'stereoMode' mode of presentation, defaults to mode 8 (Red-Blue
% Anaglyph). 'imaging' if set to 1, will use the Psychtoolbox imaging
% pipeline for stereo display -- allows to set gains for anaglyph stereo
% and other more advanced anaglyph algorithms.
%
% stereoMode 103 activates stereo display on a VR HMD.
%
% 'anaglyphmode' when imaging is enabled, allows to select the type of
% anaglyph algorithm:
%
% 0 = Standard anaglyphs.
% 1 = Gray anaglyphs.
% 2 = Half-color anaglyphs.
% 3 = Optimized color anaglyphs.
% 4 = Full color anaglyphs.
%
% See "help SetAnaglyphStereoParameters" for further description and references.
%
% 'screenid' Screen id of target display screen (on multi-display setups).
% By default, the screen with maximum id is used.
%
% If the optional flag 'hdr' is specified as non-zero, then the demo
% expects the onscreen window to display on a HDR-10 capable display device
% and system, and tries to switch to HDR mode. If the operating system+gpu
% driver+gpu+display combo does not support HDR, the demo will abort with
% an error. Otherwise it will expect the movies to be HDR-10 encoded and
% try to display them appropriately. A flag of 1 does just that. A flag of 2 will
% manually force the assumed EOTF of movies to be of type PQ, iow. assume the movie
% is a HDR-10 movie in typical Perceptual Quantizer encoding. This is useful if you
% want to play back HDR content on a system with a GStreamer version older than
% 1.18.0 installed, where GStreamer is not fully HDR capable, but this hack may
% get you limping along. Another restriction would be lack of returned HDR metadata,
% so if your HDR display expects that, you will not get the best possible quality.
% Upgrading to GStreamer 1.18 or later is advised for HDR playback.
% A 'stereoMode' of 4 or 5 will use an alternative HDR display method only available on
% Linux/X11 for dual-display HDR playback. This is currently not supported on other
% operating systems, where you only have single-display stereo for HDR playback.
%
% 'topBottom' If this optional flag is set to 1, then top-bottom encoding in the
% movie is assumed and handled accordignly, otherwise left-right encoding is assumed.
%
%
% The left image is centered on the screen, the right images position can
% be moved by moving the mouse cursor to align for inter-eye distance.
%
% Press any key to quit the player.

% History:
% 11.11.2007 Written (MK)
% 17.06.2013 Cleaned up (MK)
% 30.09.2015 Add VR HMD support. (MK)
% 18.12.2020 Add HDR support. (MK)
% 18.04.2024 Add handling of top-bottom encoded movies. (MK)

AssertOpenGL;

if nargin < 1
    error('You must at least provide the name of the movie file for stereo pair.');
end

if nargin < 2
    stereoMode = [];
end

if isempty(stereoMode)
    stereoMode = 8;
end

if nargin < 3
    imaging = [];
end

if isempty(imaging)
    imaging = 1;
end

if nargin < 4
    anaglyphmode = [];
end

if isempty(anaglyphmode)
    anaglyphmode = 0;
end

if nargin < 5
    screenid = [];
end

if isempty(screenid)
    screenid = max(Screen('Screens'));
end

if nargin < 6 || isempty(hdr)
    hdr = 0;
end

if nargin < 7 || isempty(topBottom)
    topBottom = 0;
end

% No special movieOptions by default:
movieOptions = [];

if imaging
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseVirtualFramebuffer');

    if stereoMode == 103
        PsychVRHMD('AutoSetupHMD', 'Stereoscopic', 'NoTimingSupport NoTimestampingSupport DebugDisplay');
        stereoMode = -1;
    end

    % Enable HDR display in HDR-10 mode if requested by user:
    if hdr
        PsychImaging('AddTask', 'General', 'EnableHDR');

        if ismember(stereoMode, [4, 5])
            if IsLinux && ~IsWayland
                PsychImaging('AddTask', 'General', 'UseStaticHDRHack');
            else
                warning('HDR stereoMode 4/5 for dual-display HDR unsupported on non-Linux. Ignored.');
            end
        end

        % Special hack for running HDR movie playback on GStreamer versions older
        % than 1.18.0. Those can not detect the EOTF transfer functions of HDR-10
        % video footage, neither type 14 PQ, nor type 15 HLG. If user passes in a
        % hdr == 2 flag, override automatic EOTF detection to always assume EOTF
        % type 14 instead. Type 14 is the SMPTE ST-2084 PQ "Perceptual Quantizer",
        % the most common EOTF used in typical HDR-10 movie content.
        % (Obviously, SDR content will look really weird, if played back with this
        % override in use, so viewer discretion is advised ;)):
        if hdr == 2
            movieOptions = 'OverrideEOTF=14';
        end
    end

    [win, winRect] = PsychImaging('OpenWindow', screenid, 0, [], [], [], stereoMode);
else
    [win, winRect] = Screen('OpenWindow', screenid, 0, [], [], [], stereoMode);
end
modestr = [];

if imaging
    % Set color gains. This depends on the anaglyph mode selected:
    switch stereoMode
        case 6,
            SetAnaglyphStereoParameters('LeftGains', win,  [1.0 0.0 0.0]);
            SetAnaglyphStereoParameters('RightGains', win, [0.0 0.6 0.0]);
        case 7,
            SetAnaglyphStereoParameters('LeftGains', win,  [0.0 0.6 0.0]);
            SetAnaglyphStereoParameters('RightGains', win, [1.0 0.0 0.0]);
        case 8,
            SetAnaglyphStereoParameters('LeftGains', win, [0.4 0.0 0.0]);
            SetAnaglyphStereoParameters('RightGains', win, [0.0 0.2 0.7]);
        case 9,
            SetAnaglyphStereoParameters('LeftGains', win, [0.0 0.2 0.7]);
            SetAnaglyphStereoParameters('RightGains', win, [0.4 0.0 0.0]);
        otherwise
            %error('Unknown stereoMode specified.');
    end

    if stereoMode > 5 && stereoMode < 10
        switch anaglyphmode
            case 0,
                % Default anaglyphs, nothing to do...
                modestr = 'Standard anaglyphs';
            case 1,
                SetAnaglyphStereoParameters('GrayAnaglyphMode', win);
                modestr = 'Gray anaglyph rendering';
            case 2,
                SetAnaglyphStereoParameters('HalfColorAnaglyphMode', win);
                modestr = 'Half color anaglyph rendering';
            case 3,
                SetAnaglyphStereoParameters('OptimizedColorAnaglyphMode', win);
                modestr = 'Optimized color anaglyph rendering';
            case 4,
                SetAnaglyphStereoParameters('FullColorAnaglyphMode', win);
                modestr = 'Full color anaglyph rendering';
            otherwise
                error('Invalid anaglyphmode specified!');
        end

        overlay = SetAnaglyphStereoParameters('CreateMonoOverlay', win);
        Screen('TextSize', overlay, 24);
        DrawFormattedText(overlay, ['Loading file: ' moviefile ], 0, 25, [255 255 0]);
    end
end

% Initial flip:
Screen('Flip', win);

% Open movie file and start playback:
[movie, movieduration, fps, imgw, imgh, ~, ~, hdrStaticMetaData] = Screen('OpenMovie', win, moviefile, [], [], [], [], [], movieOptions);
fprintf('Movie: %s  : %f seconds duration, %f fps, w x h = %i x %i...\n', moviefile, movieduration, fps, imgw, imgh);

if hdrStaticMetaData.Valid
    fprintf('Static HDR metadata is:\n');
    disp(hdrStaticMetaData);
    ColorGamut = hdrStaticMetaData.ColorGamut %#ok<NOPRT,NASGU>
    fprintf('\n');
    if hdr
        % If HDR mode is enabled and the movie has HDR-10 static
        % metadata attached, also provide it to the HDR display, in
        % the hope it will somehow enhance reproduction of the
        % visual movie content:
        PsychHDR('HDRMetadata', win, hdrStaticMetaData);
    end
end

Screen('PlayMovie', movie, 1, 1, 1);

% Position mouse on center of display:
[x , y] = RectCenter(winRect);
SetMouse(x, y, win);

% Hide mouse cursor:
HideCursor(screenid);

% Setup variables:
tex = 0;
imgrect = [];

if ~isempty(modestr)
    Screen('FillRect', overlay, [0 0 0 0]);
    DrawFormattedText(overlay, ['File: ' moviefile '\nOpmode: ' modestr], 0, 25, [255 255 0]);
end

try
    % Playback loop: Run until keypress or error:
    while ~KbCheck && tex~=-1
        % Fetch next image from movie:
        tex = Screen('GetMovieImage', win, movie, 1);

        % Valid image to draw?
        if tex>0
            % Query mouse position:
            x = GetMouse(win);

            % Setup drawing regions based on size of first frame:
            if isempty(imgrect)
                imgrect = Screen('Rect', tex);
                if topBottom
                    imglrect = [0, 0, RectWidth(imgrect), RectHeight(imgrect)/2];
                    imgrrect = [0, RectHeight(imgrect)/2, RectWidth(imgrect), RectHeight(imgrect)];
                else
                    imglrect = [0, 0, RectWidth(imgrect)/2, RectHeight(imgrect)];
                    imgrrect = [RectWidth(imgrect)/2, 0, RectWidth(imgrect), RectHeight(imgrect)];
                end
                sf = min([RectWidth(winRect)/RectWidth(imglrect) , RectHeight(winRect)/RectHeight(imglrect)]);
                dstrect = ScaleRect(imglrect,sf,sf);
            end

            % Left eye image == left half of movie texture:
            Screen('SelectStereoDrawBuffer', win, 0);
            Screen('DrawTexture', win, tex, imglrect, CenterRect(dstrect, winRect));

            Screen('SelectStereoDrawBuffer', win, 1);
            % Draw right image centered on mouse position -- mouse controls image
            % offsets:
            Screen('DrawTexture', win, tex, imgrrect, CenterRectOnPoint(dstrect, x, y));

            % Show at next retrace:
            Screen('Flip', win);

            % Release old image texture:
            Screen('Close', tex);
            tex = 0;
        end
        % Next frame...
    end

    % Done with playback:

    % Show mouse cursor:
    ShowCursor(screenid);

    % Stop and close movie:
    Screen('PlayMovie', movie, 0);
    Screen('CloseMovie', movie);

    % Close screen:
    sca;

    return;
catch %#ok<CTCH>
    sca;
    psychrethrow(psychlasterror);
end
