%
%  High-Speed Tracking with Kernelized Correlation Filters
%
%  Joao F. Henriques, 2014
%  http://www.isr.uc.pt/~henriques/
%
%  Main interface for Kernelized/Dual Correlation Filters (KCF/DCF).
%  This function takes care of setting up parameters, loading video
%  information and computing precisions. For the actual tracking code,
%  check out the TRACKER function.
%
%  RUN_TRACKER
%    Without any parameters, will ask you to choose a video, track using
%    the Gaussian KCF on HOG, and show the results in an interactive
%    figure. Press 'Esc' to stop the tracker early. You can navigate the
%    video using the scrollbar at the bottom.
%
%  RUN_TRACKER VIDEO
%    Allows you to select a VIDEO by its name. 'all' will run all videos
%    and show average statistics. 'choose' will select one interactively.
%
%  RUN_TRACKER VIDEO KERNEL
%    Choose a KERNEL. 'gaussian'/'polynomial' to run KCF, 'linear' for DCF.
%
%  RUN_TRACKER VIDEO KERNEL FEATURE
%    Choose a FEATURE type, either 'hog' or 'gray' (raw pixels).
%
%  RUN_TRACKER(VIDEO, KERNEL, FEATURE, SHOW_VISUALIZATION, SHOW_PLOTS)
%    Decide whether to show the scrollable figure, and the precision plot.
%
%  Useful combinations:
%  >> run_tracker choose gaussian hog  %Kernelized Correlation Filter (KCF)
%  >> run_tracker choose linear hog    %Dual Correlation Filter (DCF)
%  >> run_tracker choose gaussian gray %Single-channel KCF (ECCV'12 paper)
%  >> run_tracker choose linear gray   %MOSSE filter (single channel)
%
%   revised by: Yang Li, August, 2014
%   revised by: Haoyi Ma, December, 2018

function rect_result = run_tracker(video, kernel_type, feature_type, show_visualization, show_plots)

	%path to the videos (you'll be able to choose one with the GUI).
	base_path ='./data';

	%default settings
	if nargin < 1, video = 'choose'; end
	if nargin < 2, kernel_type = 'linear'; end
	if nargin < 3, feature_type = 'hogcolor'; end
	if nargin < 4, show_visualization = ~strcmp(video, 'all'); end
	if nargin < 5, show_plots = ~strcmp(video, 'all'); end

	kernel.type = kernel_type;
	features.gray = false;
	features.hog = false;
    features.hogcolor = true;
	
	padding = 1.5;  %extra area surrounding the target
	lambda = 3e-4;  %regularization
	output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)
	
	switch feature_type
	case 'hogcolor'
		interp_factor = 0.004;
		kernel.sigma = 0.5;
		features.hogcolor = true;
		features.hog_orientations = 9;
		cell_size = 4;	
	otherwise
		error('Unknown feature.')
	end

	assert(any(strcmp(kernel_type, {'linear', 'polynomial', 'gaussian'})), 'Unknown kernel.')

	switch video
	case 'choose'
		%ask the user for the video, then call self with that video name.
		video = choose_video(base_path);
		if ~isempty(video)
			[~] = run_tracker(video, kernel_type, ...
				feature_type, show_visualization, show_plots);
			
			if nargout == 0  %don't output precision as an argument
				clear precision
			end
        end
		
	otherwise
		%we were given the name of a single video to process.
		%get image file names, initial state, and ground truth for evaluation
		[img_files, pos, target_sz, ~, video_path] = load_video_info(base_path, video);
        search_size = [1 0.995 1.005 0.985 0.99 1.01 1.015];
		%call tracker function with all the relevant parameters
		[rects, ~] = tracker(video_path, img_files, pos, target_sz, ...
            padding, kernel, lambda, output_sigma_factor, interp_factor, cell_size, ...
            search_size, features, show_visualization);
		rect_result = rects;
	end
end
