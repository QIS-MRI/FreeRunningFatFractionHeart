function [twix_obj, rawData] = fReadSiemensRawData_FreeRunning_MultiEcho_v2021(filepathRawData)
%--------------------------------------------------------------------------
%
%   fReadRawDataSiemens_FreeRunning_MultiEcho_v2021     read raw data from Siemens scanner
%
%     [twix_obj rawData] = fReadSiemensRawData_FreeRunning_MultiEcho_v2021( filepathRawData );
%
%     INPUT:    filepathRawData Raw file path
%
%     OUTPUT:   twix_obj        Twix object containing all the header info
%               rawData         Raw data
%
%--------------------------------------------------------------------------

  % Add ReadRawDataSiemens directory to matlab path
    tmpdir = which('fReadSiemensRawData'); % find fReadSiemensRawData.m
	[tmpdir, ~] = fileparts(tmpdir);
    %addpath([tmpdir filesep 'ReadRawDataSiemens' filesep 'mapVBVD_multiRAID']);
    addpath([tmpdir filesep 'mapVBVD']);
    fprintf('Start reading Siemens raw data on %s\n', datestr(now));
    tic;
    
  % Reading RAW DATA header (raw data are actually read only when needed);
    fprintf('... read raw data header ...\n');
    twix_obj_multi = mapVBVD_JH(filepathRawData);
    
    if iscell(twix_obj_multi)
        twix_obj = twix_obj_multi{2};
    else
        twix_obj = twix_obj_multi;
    end
    
    
    twix_obj.image.flagIgnoreSeg = true; %(essential to read the data correctly) 
    fprintf('... read raw data ...\n');
    
          % READ the complete RAW DATA
  %     Raw data format = 2*Np x Nc x Ns
  %     where Np is the number of readout point, Nc is the number of
  %     channels, Ns is the total number of shots, and the factor 2 
  %     accounts for the oversampling in the readout direction.
  %
  % Order of raw data:
  %  1) Columns
  %  2) Channels/Coils
  %  3) Lines
  %  4) Partitions
  %  5) Slices
  %  6) Averages
  %  7) (Cardiac-) Phases
  %  8) Contrasts/Echoes
  %  9) Measurements
  % 10) Sets
  % 11) Segments
  % 12) Ida
  % 13) Idb
  % 14) Idc
  % 15) Idd
  % 16) Ide
    
    MEFlag = false;
    if twix_obj.image.NEco > 1
        MEFlag = true;
        disp([num2str(twix_obj.image.NEco) ' echoes detected...']);
        rawData = twix_obj.image.unsorted();
    else
        disp('Only 1 echo detected...');
        rawData = twix_obj.image{''};
    end
    
    twix_obj.MEFlag = MEFlag;
    
    % Size of the non-squeezed raw data
    dataSize = twix_obj.image.dataSize;
    if MEFlag
        dataSize(8) = 1;
    end

  % Permuting raw data to satisfy the following convention
  %     Raw data format = 2*Np x Ns x Nc
  %     where Np is the number of readout point, Nc is the number of
  %     channels, Ns is the total number of shots, and the factor 2 
  %     accounts for the oversampling in the readout direction.
  %
  % Permute data to follow convention [Nx Ny Nz Nt Nc], i.e.,
  %  1) Columns
  %  2) Lines 
  %  3) Slices
  %  4) (Cardiac-) Phases 
  %  5) Channels/Coils
  %  6) Partitions 
  %  7) Averages
  %  8) Contrasts/Echoes
  %  9) Measurements
  % 10) Sets
  % 11) Segments
  % 12) Ida
  % 13) Idb
  % 14) Idc
  % 15) Idd
  % 16) Ide
    
  rawData = reshape(rawData, dataSize);
  fprintf('... permute raw data ...\n');
  order = [1 3 5 7 2 4 6 8 9 10 11 12 13 14 15 16];
  rawData = permute( rawData, order );
  
  tmpCell = twix_obj.image.dataDims;
  
  for i = 1:length(order)
      tmpCell{i} = twix_obj.image.dataDims{order(i)};
  end
  twix_obj.image.dataDims = tmpCell;

  fprintf('Done!\n')
  
  % Compute elapsed time
  toc;
  
end


