% Setup the paths to the functions in the folders of this project
function [] = setup()

currentFile = mfilename('fullpath');
[pathstr,~,~] = fileparts(currentFile);

addpath(fullfile(pathstr, 'lib/skin_cell'));
addpath(fullfile(pathstr, 'lib/hexa2'));
addpath(fullfile(pathstr, 'lib/draw'));

   
end
