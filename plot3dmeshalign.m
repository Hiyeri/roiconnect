function plot3dmeshalign(filename1, filename2, transform, color1, color2)

if isempty(filename1)
    return;
end
if nargin < 3
    transform = [];
end
if nargin < 4
    color1  = [1 1 1]*0.5;
end
if nargin < 5
    color2  = [1 0 0];
end

fig = figure;
ax = axes('unit', 'normalized', 'position', [ 0.05 0.05 0.9 0.9]);
[pos1,tri1] = loadmeshdata(filename1);
[pos2,tri2] = loadmeshdata(filename2, transform);
if isempty(pos2)
    pos2 = loadvolumedata(filename2, transform);
    title('Vertices falling outside the brain mesh will be automatically removed');
else
    title('Vertices falling outside the brain mesh will automatically be moved inside the mesh');
end
axis off; 
try, ax.Toolbar.Visible = 'off'; catch, end

ratio = abs( max(reshape(pos1, numel(pos1), 1))/max(reshape(pos2, numel(pos2), 1)) );
if ratio > 100 || ratio < 0.01
    disp('Warning: widely different scale, one of the mesh might not be visible');
end

pairwiseDist = ones(size(pos1,1),4);
colors = pairwiseDist(:,4)*color1;

axes('unit', 'normalized', 'position', [ 0.05 0.05 0.9 0.9]);
patch('Faces',tri1,'Vertices',pos1, 'FaceVertexCdata',colors,'facecolor','interp','edgecolor','none', 'facealpha', 0.5);
hold on
if ~isempty(tri2)
    pairwiseDist = ones(size(pos2,1),4);
    colors = pairwiseDist(:,4)*color2;
    patch('Faces',tri2,'Vertices',pos2, 'FaceVertexCdata',colors,'facecolor','interp','edgecolor','none', 'facealpha', 0.5);
else
    plot3(pos2(:,1),pos2(:,2),pos2(:,3), '.', 'color', color2);
end

axisBrain = gca;
axis equal;
axis off;
hold on;

% change lighting
set(fig, 'renderer', 'opengl');
lighting(axisBrain, 'phong');
hlights = findobj(axisBrain,'type','light');
delete(hlights)
hlights = [];
camlight(0,0);
camlight(90,0);
camlight(180,0);
camlight(270,0);
camproj orthographic
axis vis3d
camzoom(1);
hlegend = legend({'Head model' 'ROI source model' });
set(hlegend, 'position', [0.7473 0.7935 0.2304 0.0774]);
                    
% ----------------------------------------
% function to load mesh and transform mesh
% ----------------------------------------
function [pos,tri] = loadmeshdata(filename, transform)

pos = [];
tri = [];
if ischar(filename)
    try
        f = load('-mat', filename);
    catch
        return;
    end
else
    f = filename;
end

if isfield(f, 'cortex')
    f = f.cortex;
end
if isfield(f, 'SurfaceFile') % Brainstrom leadfield
    p = fileparts(fileparts(fileparts(filename)));
    try
        f = load('-mat', fullfile(p, 'anat', f.SurfaceFile));
    catch
        error('Cannot find Brainstorm mesh file')
    end
end
if isfield(f, 'pos')
    pos = f.pos;
    tri = f.tri;
elseif isfield(f, 'Vertices')
    pos = f.Vertices;
    tri = f.Faces;
elseif isfield(f, 'vertices')
    pos = f.vertices;
    tri = f.faces;
elseif isfield(f, 'vol')
    pos = f.vol.bnd(3).pnt;
    tri = f.vol.bnd(3).tri;
else
    return
end

if size(pos,1) == 3
    pos = pos';
end
if nargin > 1 && ~isempty(transform)
    pos = traditionaldipfit(transform)*[pos ones(size(pos,1),1)]';
    pos(4,:) = [];
    pos = pos';
end

% ---------------------
% function to load mesh
% ---------------------
function [pos] = loadvolumedata(filename, transform)

if ischar(filename)
    atlas = ft_read_atlas(filename);
else
    atlas = filename;
end

if isfield(atlas, 'tissue')
    mri = sum(atlas.tissue(:,:,:,:),4) > 0;
elseif isfield(atlas, 'brick0')
    mri = sum(atlas.brick0(:,:,:,:),4) > 0;
    mri = atlas.brick1(:,:,:,1);
    transform2 = atlas.transform;
else
    error('Unknown MRI file/structure format');
end
[r,c,v] = ind2sub(size(mri),find(mri));
pos = [r c v];
pos = atlas.transform*[pos ones(size(pos,1),1)]';
pos(4,:) = [];
pos = pos';

if nargin > 1 && ~isempty(transform)
    pos = traditionaldipfit(transform)*[pos ones(size(pos,1),1)]';
    pos(4,:) = [];
    pos = pos';
end
