function remCH = removeNoisyChannels(d, varargin)

if nargin == 2
    SNRrange = varargin{1};
    dRange = [-inf inf];
elseif nargin == 3
    dRange = varargin{1};
    SNRrange = varargin{2};
else
    error('Usage: removeNoisyChannels(d, SNRrange) or removeNoisyChannels(d, dRange, SNRrange).');
end

n_ch = size(d,2)/2;

% Split dei canali
d1 = d(:,1:n_ch);
d2 = d(:,n_ch+1:end);

% Calcolo SNR
SNR1 = mean(d1) ./ std(d1);
SNR2 = mean(d2) ./ std(d2);

% Min e Max per colonna
d1_min = min(d1);
d1_max = max(d1);

d2_min = min(d2);
d2_max = max(d2);

% Condizioni
remCH1 = (SNR1 > SNRrange) & (d1_min > dRange(1)) & (d1_max < dRange(2));
remCH2 = (SNR2 > SNRrange) & (d2_min > dRange(1)) & (d2_max < dRange(2));

% Combine
remCH = remCH1 & remCH2;

% Output come vettore colonna duplicato
remCH = [remCH(:); remCH(:)];

end
