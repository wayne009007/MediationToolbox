% This script runs and saves tables, images, and clusters
% for all effects of a two-level mediation model
%
% The thresholds are fixed right now, and two sets of results are run:
% One at .001, and one with an across-contrast FDR correction at q < .05
%
% - Reports all paths (a, b, ab), conjunctions, and 2nd-level moderators if
% available.
%
% - Set mask and underlay image: uses those in EXPT.mask and EXPT.overlay if
% available
% - create EXPT variable with results mask and overlay before running this script if desired,
% or else the script will try to find default options stored with the
% mediation_SETUP.mat file
%
% clpos_data and clneg_data contain clusters of significant results, with
% data extracted and stored in the clusters structure. This data can be
% reused later to re-run mediation in ROIs, etc.
%
% For an updated version that prints HTML reports, but with less functionality so far,
% See also:
% publish_mediation_report.m
% mediation_brain_results_report.m

% Display helper functions: Called later
% --------------------------------------------------------

dashes = '----------------------------------------------';
printstr = @(dashes) disp(dashes);
printhdr = @(str) fprintf('%s\n%s\n%s\n', dashes, str, dashes);

% Load SETUP
% ----------------------------------------------------------------
if ~exist(fullfile(pwd, 'mediation_SETUP.mat'), 'file')
    error('Cannot find mediation_SETUP.mat in current directory. Please go to a valid mediation directory.');
else
    load(fullfile(pwd, 'mediation_SETUP.mat'))
end

% single or multi-level dir?
% ----------------------------------------------------------------
if exist(fullfile(pwd, 'mask.img'), 'file') && isfield(SETUP, 'data') && iscell(SETUP.data.X)  % multilevel mediation dirs have this image
    ismultilevel = 1;
elseif isfield(SETUP, 'data') && iscell(SETUP.data.X)
    warning('Multilevel mediation: mask.img is missing');
else
    % SETUP.X, Y Z instead of SETUP.data
    ismultilevel = 0;
end

% input EXPT variable with results mask and overlay, or else will try to
% find defaults.
% ----------------------------------------------------------------

printhdr('Analysis Mask')

if exist('EXPT', 'var')
    overlay = EXPT.overlay;
    mask = EXPT.mask;           % you can apply a mask here, or use 'mask.img' by def.
else
    
    if ismultilevel
        disp('Using mask.img stored in current directory (automatically written for mediation analyses) for mask.');
        mask = fullfile(pwd, 'mask.img');
    else
        % single-level mask stored here
        mask = SETUP.mask;
    end
    disp('Using default anatomical underlay image.')
    
    %overlay = which('spm2_single_subj_T1_scalped.img');
    overlay = which('SPM8_colin27T1_seg.img');
    %overlay = [];
end

if ~exist(mask, 'file')
    disp('Mask cannot be found/is not a valid file.  Using mask.img in mediation results directory.');
    
    mask = fullfile(pwd, 'mask.img');
    
    if ~exist(mask, 'file')
        tmp = fmri_data('X-M_effect.img');
        tmp.dat = double(tmp.dat ~= 0 & ~isnan(tmp.dat));
        tmp.fullpath = fullfile(pwd, 'mask.img');
        write(tmp);
    end
    
end

try
    mask_fig_handle = montage_clusters(mask);
    set(mask_fig_handle, 'Name', 'Mask image');
catch
    disp('ERROR MAKING MONTAGE OF MASK. SKIPPING. WRONG VERSION OF MONTAGE_CLUSTERS.M?');
end

drawnow; snapnow;

pthresh = [.005 .01 .05];  %[.005 .01 .05]; %[.001 .005 .01]; %'fdr';            % specify 'fdr' or a series of p thresholds
kthresh = [3 1 1];          % specify a series of extent thresholds

zstr = '-------------------------------------------------------------------';

reversecolors = 0;

if reversecolors
    negcolors = { [1 1 0] [1 .5 0] [1 .3 .3] };
    poscolors = { [0 0 1] [0 .5 1] [.3 .3 1] };
else
    poscolors = { [1 1 0] [1 .5 0] [1 .3 .3] };
    negcolors = { [0 0 1] [0 .5 1] [.3 .3 1] };
end

if strcmp(pthresh, 'fdr')
    
    SETUP = mediation_brain_corrected_threshold('fdr', 'mask', mask);
    fdrthresh = SETUP.fdr_p_thresh;
    
    if isempty(fdrthresh) || fdrthresh <= 0
        disp('No FDR-significant results');
        return
    end
    
    if fdrthresh < .001
        thresholds = [fdrthresh .001, .005];
    elseif fdrthresh < .005
        thresholds = [fdrthresh .005, .01];
    elseif fdrthresh < .01
        thresholds = [fdrthresh .01, .05];
    end
    
    printhdr('Overlap between Paths a and b')

    warning off
    mediation_brain_results_a_b_overlap('fdr', 'k', kthresh(1), 'overlay', overlay, 'save', 'mask', mask, 'slices');
    warning on
    drawnow; snapnow;

    printhdr('MEDIATION: A, B, A*B CONJUNCTION')

    fprintf('%s\n%s\nMEDIATION: A, B, A*B CONJUNCTION \n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('all', 'thresh', thresholds, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask, 'conj');
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    fprintf('%s\n%s\nMEDIATION: PATH A\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('a', 'thresh', thresholds, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    fprintf('%s\n%s\nMEDIATION: PATH B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('b', 'thresh', thresholds, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    fprintf('%s\n%s\nMEDIATION: PATH A*B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('ab', 'thresh', thresholds, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    if exist(fullfile(pwd, 'ap_L2mod.img'), 'file')
        
        printhdr('Second-level moderators')

        fprintf('%s\n%s\nMEDIATION 2ND LEVEL MODERATOR: PATH A\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
        
        [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
            ('al2mod', 'thresh', thresholds, 'size', kthresh, 'prune', ...
            'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
        
        drawnow; snapnow;

        % close figures
        close, close, close
        
        fprintf('%s\n%s\nMEDIATION 2ND LEVEL MODERATOR: PATH B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
        
        [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
            ('bl2mod', 'thresh', thresholds, 'size', kthresh, 'prune', ...
            'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
        
        drawnow; snapnow;

        % close figures
        close, close, close
        
        fprintf('%s\n%s\nMEDIATION 2ND LEVEL MODERATOR: PATH A*B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
        
        [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
            ('abl2mod', 'thresh', thresholds, 'size', kthresh, 'prune', ...
            'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
        
        drawnow; snapnow;

        % close figures
        close, close, close
        
    end
    
else % non-FDR option
    
    printhdr('Overlap between Paths a and b')

    fprintf('%s\n%s\nMEDIATION: OVERLAP BETWEEN PATH A AND B MAPS\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    warning off
    mediation_brain_results_a_b_overlap('p', pthresh(1), 'k', kthresh(1), 'overlay', overlay, 'save', 'mask', mask, 'slices');
    warning on
    
    printhdr('MEDIATION:  A, B, A*B CONJUNCTION')

    fprintf('%s\n%s\nMEDIATION:  A, B, A*B CONJUNCTION \n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('all', 'thresh', pthresh, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask, 'conj');
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    % Separate paths
    % -------------------------------------------------------------------------


    fprintf('%s\n%s\nMEDIATION: PATH A\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('a', 'thresh', pthresh, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    fprintf('%s\n%s\nMEDIATION: PATH B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('b', 'thresh', pthresh, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    fprintf('%s\n%s\nMEDIATION: PATH A*B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
    
    [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
        ('ab', 'thresh', pthresh, 'size', kthresh, 'prune', ...
        'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
    
    drawnow; snapnow;

    % close figures
    close, close, close
    
    % Level-2 moderators
    % -------------------------------------------------------------------------


    if exist(fullfile(pwd, 'ap_L2mod.img'), 'file')
        
        printhdr('Second-level moderators')

        fprintf('%s\n%s\nMEDIATION 2ND LEVEL MODERATOR: PATH A\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
        
        [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
            ('al2mod', 'thresh', pthresh, 'size', kthresh, 'prune', ...
            'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
        
        drawnow; snapnow;

        % close figures
        close, close, close
        
        fprintf('%s\n%s\nMEDIATION 2ND LEVEL MODERATOR: PATH B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
        
        [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
            ('bl2mod', 'thresh', pthresh, 'size', kthresh, 'prune', ...
            'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
       
        drawnow; snapnow;

        % close figures
        close, close, close
        
        fprintf('%s\n%s\nMEDIATION 2ND LEVEL MODERATOR: PATH A*B\n%s\n%s\n\n', zstr, zstr, zstr, zstr);
        
        [clpos, clneg, clpos_data, clneg_data, clpp2, clnn2] = mediation_brain_results ...
            ('abl2mod', 'thresh', pthresh, 'size', kthresh, 'prune', ...
            'tables', 'slices', 'save', 'overlay', overlay, 'mask', mask);
       
        drawnow; snapnow;

        % close figures
        close, close, close
        
    end
    
end


% Clean up: Move files to subdirectories
% -------------------------------------------------------------------------

figdir = fullfile(pwd, 'figures');
if ~exist(figdir, 'dir'), mkdir(figdir); end
[SUCCESS,MESSAGE,MESSAGEID] = movefile('*.png', figdir);

logdir = fullfile(pwd, 'results_logs');
if ~exist(logdir, 'dir'), mkdir(logdir); end
[SUCCESS,MESSAGE,MESSAGEID] = movefile('*_log.txt', logdir);

tabledir = fullfile(pwd, 'results_tables');
if ~exist(tabledir, 'dir'), mkdir(tabledir); end
[SUCCESS,MESSAGE,MESSAGEID] = movefile('*_results.txt', tabledir);

cldir = fullfile(pwd, 'clusters_with_extracted_data');
if ~exist(cldir, 'dir'), mkdir(cldir); end
[SUCCESS,MESSAGE,MESSAGEID] = movefile('*_prune.mat', cldir);
[SUCCESS,MESSAGE,MESSAGEID] = movefile('*_clusters.mat', cldir);


