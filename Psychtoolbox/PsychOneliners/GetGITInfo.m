function gitInfo = GetGITInfo(directory)
% gitInfo = GetGITInfo(directory)
%
% Description:
% Retrieves the git information on a specified directory or file.  This is
% essentially a wrapper around the shell command "git".
%
% Input:
% directory (string) - Directory name of interest.
%
% Output:
% gitInfo (struct) - Structure containing the following information:
%   Path
%   Describe
%	Revision
%   LastCommit
%   RemoteRepository
%   RemoteBranch
%   LocalBranch
%
% 'gitInfo' will be empty if there is no git info for directory or if directory 
% does not exist.
%
% 7/11/13  dhb  Wrote it based on GetSVNInfo
% 7/12/13  dhb  More info, based on Ben Heasly's version of this in RenderToolbox3.
% 12/2/18  dhb  Add --no-pager to the git branch call, based on email from
%               Henryk Blasniski who says this will work better across platforms.
%               The change did not break anything obvious on my machine.
% 12/8/18  dhb  Same edit, line 99

tempFile = tempname();

if nargin ~= 1
    error('Usage: gitInfo = GetGITInfo(directory)');
end

gitInfo = [];
if (~exist(directory,'dir'))
    return;
end

% Look to see if we can find the git executable on the path.
gitPath = GetGitPath;
if ~exist(gitPath, 'file')
    fprintf('*** Failed to find git, returning empty.\n');
    return;
end
if IsWin
    % allow spaces in path to git
    gitPath = ['"' gitPath '"'];
end

% Get the git describe info of the specified directory.
curDir = pwd;
cd(directory);
[status, result] = system([gitPath 'git describe --always']);
cd(curDir);
if status == 0
    gitInfo.Path = directory;
    gitInfo.Describe = result(1:end-1);
else
    return;
end

% get revision number
cd(directory);
[status, result] = system([gitPath 'git rev-parse HEAD']);
cd(curDir);
if status == 0
    gitInfo.Revision = getStringLines(result);
end

% get recent commit
%   send to file, because terminal is shell is non-interactive
cd(directory);
[status] = system([gitPath 'git log --max-count=1 > ' tempFile]);
if status == 0
    fid = fopen(tempFile);
    result = char(fread(fid))';
    gitInfo.LastCommit = getStringLines(result);
    fclose(fid);
end
delete(tempFile);
cd(curDir);

% get remote repository urls
cd(directory);
[status, result] = system([gitPath 'git remote -v']);
cd(curDir);
if status == 0
    gitInfo.RemoteRepository = getStringLines(result);
end

% get remote branches
cd(directory);
[status, result] = system([gitPath 'git --no-pager branch -r']);
cd(curDir);
if status == 0
    gitInfo.RemoteBranch = getStringLines(result);
end

% get local branches
cd(directory);
[status, result] = system([gitPath 'git --no-pager branch']);
cd(curDir);
if status == 0
    gitInfo.LocalBranch = getStringLines(result);
end

end

%% Break a multi-line string into a cell array of lines.
function lines = getStringLines(string)
tokens = regexp(string, '([^\r\n]*)\r?\n?', 'tokens');
nLines = numel(tokens);
if 0 == nLines
    lines = {};
elseif 1 == nLines
    lines = tokens{1}{1};
else
    lines = cell(1, nLines);
    for ii = 1:nLines
        lines{ii} = tokens{ii}{1};
    end
end
end