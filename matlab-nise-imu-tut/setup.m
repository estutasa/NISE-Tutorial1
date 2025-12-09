% Setup the paths to the functions in the folders of this project
function [] = setup()

currentFile = mfilename('fullpath');
[pathstr,~,~] = fileparts(currentFile);


addpath(fullfile(pathstr, 'lib/draw'));
    
end
