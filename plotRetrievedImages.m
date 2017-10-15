function plotRetrievedImages(imdb, res, varargin)
% PLOTRETRIEVEDIMAGES  Displays search results
%   PLOTRETRIEVEDIMAGES(IMDB, SCORES) displays the images in the
%   database IMDB that have largest SCORES. SCORES is a row vector of
%   size equal to the number of images in IMDB.

% Author: Andrea Vedaldi and Mireca Cimpoi

opts.num = 16 ;
opts.labels = [] ;
opts = vl_argparse(opts, varargin) ;

if isstruct(res)
  scores = res.geom.scores ;
else
  scores = res ;
end

[scores, perm] = sort(scores, 'descend') ;
if isempty(opts.labels), opts.labels = zeros(1,numel(scores)) ; end

clf ;

for rank = 1:opts.num
  vl_tightsubplot(opts.num, rank) ;
  ii = perm(rank) ;
  im0 = getImage(imdb, ii) ;
  data.h(rank) = imagesc(im0) ; axis image off ; hold on ;
  switch opts.labels(ii)
    case 0, cl = 'y' ;
    case 1, cl = 'g' ;
    case -1, cl = 'r' ;
  end
  text(0,0,sprintf('%d: score:%.3g', rank, full(scores(rank))), ...
       'background', cl, ...
       'verticalalignment', 'top') ;

  set(data.h(rank), 'ButtonDownFcn', @zoomIn) ;
end

% for interactive plots
data.imdb = imdb ;
data.perm = perm ;
data.scores = scores ;
data.labels = opts.labels ;
data.res = res ;
guidata(gcf, data) ;

% --------------------------------------------------------------------
function im = getImage(imdb, ii)
% --------------------------------------------------------------------
imPath = fullfile(imdb.dir, imdb.images.name{ii}) ;
im = [] ;

if exist(imPath, 'file'), im = imread(imPath) ; end

if isempty(im) && isfield(imdb.images, 'wikiName')
  name = imdb.images.wikiName{ii} ;
  [~,~,url] = get_image_url(name) ;
  fprintf('Downloading image ''%s'' (%s)\n', url, name) ;
  if ~isempty(url)
    im = imread(url) ;
    width = size(im,1) ;
    height = size(im,2) ;
    scale = min([1, 1024/width, 1024/height]) ;
    im = imresize(im, scale) ;
  end
end

if isempty(im)
  im = checkerboard(10,10) ;
  warning('Could not retrieve image ''%s''', imdb.images.name{ii}) ;
end

% --------------------------------------------------------------------
function zoomIn(h, event, data)
% --------------------------------------------------------------------
data = guidata(h) ;
rank = find(h == data.h) ;

if ~isstruct(data.res), return ; end

% get query image
if numel(data.res.query.image) == 1
  ii = vl_binsearch(data.imdb.images.id, data.res.query.image) ;
  im1 = imread(fullfile(data.imdb.dir, data.imdb.images.name{ii})) ;
else
  im1 = data.res.query.image ;
end

% get retrieved image
ii = data.perm(rank) ;
im2 = getImage(data.imdb, ii) ;

% plot matches
figure(100) ; clf ;
plotMatches(im1,im2,...
            data.res.features.frames, ...
            data.imdb.images.frames{ii}, ...
            data.res.geom.matches{ii}) ;

% if we have a wikipedia page, try opening the URL too
if isfield(data.imdb.images, 'wikiName')
  name = data.imdb.images.wikiName{ii} ;
  [~,descrUrl] = get_image_url(name) ;
  fprintf('Opening url %s\n', descrUrl) ;
  web('url',descrUrl) ;
  return ;
end

% --------------------------------------------------------------------
function [comment, descUrl, imgUrl] = get_image_url(imgTitle)
% --------------------------------------------------------------------

title = urlencode(imgTitle);
content = strcat('https://en.wikipedia.org/w/api.php?action=query&format=json&titles=',title,'&prop=imageinfo&iiprop=url|comment');
to_parse = urlread(content);

pattern_url = '(?<="url":").*?(?=")';
pattern_desc = '(?<="descriptionurl":").*?(?=")';
pattern_comment = '(?<="comment":").*?(?=")';

comment = regexp(to_parse, pattern_comment, 'match');
descUrl = regexp(to_parse, pattern_desc, 'match');
imgUrl = regexp(to_parse, pattern_url, 'match');

comment = char(comment{1});
descUrl = char(descUrl{1});
imgUrl  = char(imgUrl{1});

