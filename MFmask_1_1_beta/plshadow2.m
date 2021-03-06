%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% A stratied random sampling approach was applied in this version.
% Speed up by combining the correction for NIR and SWIR bands together.
% by Shi.
% at 23,Feb.,2017
%
% fix the bug that the imfill function will go with errors when including
% Nan value.     (Shi 12/20/2017)
% No topo correction when no DEMs (Shi 9/13/2017)
% fixed the bug of the wrong selection of samples (Shi 2/24/2017)
% When c is calculated as Nan, this function will not make the topo correction (Shi 3/8/2018)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function masker_shadow = plshadow2( data_nir,data_swir,data_clear_land,masker_observation,percent_low,...
    sun_zenith_deg,sun_azimuth_deg, slope_data,aspect_data,dim)
% get potential layer
    %% SCS+C for topo correct...
    if ~isequal(slope_data,0)&&~isequal(aspect_data,0)
        [data_nir,data_swir]=getDataTopoCorrected(data_nir,data_swir,data_clear_land,sun_zenith_deg,sun_azimuth_deg, slope_data,aspect_data,dim );
    end
    % imwrite(double(data_nir./10000),'F:\Data\online file\LE71290402002216-SC20151210220703\LE71290402002216-SC20151210220703\data_nir_scs.tif');
% imwrite(double(data_swir./10000),'F:\Data\online file\LE71290402002216-SC20151210220703\LE71290402002216-SC20151210220703\data_swir_scs.tif');
    clear sun_zenith_deg sun_azimuth_deg slope_data aspect_data;
 %% band 4 flood fill
    % estimating background (land) Band 4 ref
    backg_b4=prctile(data_nir(data_clear_land),100*percent_low);
    data_nir(masker_observation==0)=backg_b4;
    data_nir(isnan(data_nir(:)))=backg_b4;
    clear backg_b4;
    % fill in regional minimum Band 4 ref
    data_nir_filled=imfill(data_nir);
    data_nir_dif=data_nir_filled-data_nir;
    clear data_nir data_nir_filled;

    %% band 5 flood fill
    % estimating background (land) Band 4 ref
    backg_b5=prctile(data_swir(data_clear_land),100*percent_low);
    data_swir(masker_observation==0)=backg_b5;
    data_swir(isnan(data_swir(:)))=backg_b5;
    clear backg_b5;
    clear data_clear_land percent_low;
    % fill in regional minimum Band 5 ref
    data_swir_filled=imfill(data_swir);
    data_swir_dif=data_swir_filled-data_swir;
    clear data_swir data_swir_filled;
    
    %% compute shadow probability
    shadow_prob=min(data_nir_dif,data_swir_dif);
    % get potential cloud shadow
    
    masker_shadow=zeros(dim,'uint8'); % shadow mask
    masker_shadow(shadow_prob>200)=1;
    masker_shadow(masker_observation==0)=255;
end
% null fitting process.
% function [data_nir,data_swir] = getDataTopoCorrected(data_nir_ori,data_swir_ori,index_exclude_cloud_water,sun_zenith_deg,sun_azimuth_deg, slope_data,aspect_data,dim )
%     sun_zenith_rad=deg2rad(sun_zenith_deg);
%     sun_zenith_cos=cos(sun_zenith_rad);
%     sun_zenith_sin=sin(sun_zenith_rad);
% %     clear sun_zenith_deg sun_zenith_rad sun_zenith_rad;
%     cos_sita=sun_zenith_cos.*cos(deg2rad(slope_data))+sun_zenith_sin.*sin(deg2rad(slope_data)).*cos(deg2rad(sun_azimuth_deg-aspect_data));
% %     clear aspect_data;
% %     cos_sita_exclude_cloud=cos_sita(index_exclude_cloud_water);
% %     data_exclude_cloud=data_ori(index_exclude_cloud_water);
% %     clear index_exclude_cloud_water sun_zenith_deg sun_azimuth_deg;
% %     c_fitted=polyfit(double(cos_sita_exclude_cloud),double(data_exclude_cloud),1);  
% %     clear cos_sita_exclude_cloud data_exclude_cloud; 
% %     c=c_fitted(1,2)/c_fitted(1,1);
% %     clear c_fitted;
%     data_nir=double(data_nir_ori).*(cos(deg2rad(slope_data)).*sun_zenith_cos)./cos_sita;
%     data_swir=double(data_swir_ori).*(cos(deg2rad(slope_data)).*sun_zenith_cos)./cos_sita;
% %     figure;plot(double(cos_sita_exclude_cloud),double(data_corected(index_exclude_cloud_water)),'r.');axis([-0.2 1.2 0 9000]);
% %     figure;plot(double(cos_sita_exclude_cloud),double(data_exclude_cloud),'r.');axis([-0.2 1.2 0 9000]);
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CSC+C stratied on cos i with 0.1 increasement. a total of 50,000 pixels.
function [data_nir,data_swir] = getDataTopoCorrected(data_nir_ori,data_swir_ori,index_exclude_cloud_water,sun_zenith_deg,sun_azimuth_deg, slope_data,aspect_data,dim )
    sun_zenith_rad=deg2rad(sun_zenith_deg);
    sun_zenith_cos=cos(sun_zenith_rad);
    sun_zenith_sin=sin(sun_zenith_rad);
    clear sun_zenith_deg sun_zenith_rad sun_zenith_rad;
    cos_sita=sun_zenith_cos.*cos(deg2rad(slope_data))+sun_zenith_sin.*sin(deg2rad(slope_data)).*cos(deg2rad(sun_azimuth_deg-aspect_data));
    clear aspect_data;
    cos_sita_exclude_cloud=cos_sita(index_exclude_cloud_water);
    % random stratied sampling
    cos_sita_min=min(cos_sita_exclude_cloud);
    cos_sita_max=max(cos_sita_exclude_cloud);
    total_sample=50000;
    cos_sita_interval=0.1;
    samples_ids= stratiedSampleHanlder(cos_sita_exclude_cloud,cos_sita_min,cos_sita_max,dim,total_sample,cos_sita_interval,0);
    cos_sita_samples=cos_sita_exclude_cloud(samples_ids);
    clear cos_sita_exclude_cloud cos_sita_min cos_sita_max total_sample cos_sita_interval;
    % for NIR
    data_nir_ori_tmp=data_nir_ori(index_exclude_cloud_water);
    data_samples_nir=data_nir_ori_tmp(samples_ids);
    clear data_nir_ori_tmp;
    c_fitted=polyfit(double(cos_sita_samples),double(data_samples_nir),1);  
%     figure;plot(double(cos_sita_samples),double(data_samples_nir),'r.');
    c=c_fitted(1,2)/c_fitted(1,1);
    clear c_fitted;
    if isnan(c)
        data_nir=data_nir_ori;
    else
        data_nir=double(data_nir_ori).*(cos(deg2rad(slope_data)).*sun_zenith_cos+c)./(cos_sita+c);
    end
    % data_nir=double(data_nir_ori).*(cos(deg2rad(slope_data)).*sun_zenith_cos+c)./(cos_sita+c);
    % for SWIR
    data_swir_ori_tmp=data_swir_ori(index_exclude_cloud_water);
    data_samples_swir=data_swir_ori_tmp(samples_ids);
    clear data_swir_ori_tmp;
    c_fitted=polyfit(double(cos_sita_samples),double(data_samples_swir),1);
    c=c_fitted(1,2)/c_fitted(1,1);
    clear c_fitted samples_ids;
    if isnan(c)
        data_swir=data_swir_ori;
    else
        data_swir=double(data_swir_ori).*(cos(deg2rad(slope_data)).*sun_zenith_cos+c)./(cos_sita+c);
    end
end
% % CSC+C
% function [data_corected,mm] = getDataTopoCorrected(data_ori,data_ori1,index_exclude_cloud_water,sun_zenith_deg,sun_azimuth_deg, slope_data,aspect_data,dim)
%     sun_zenith_rad=deg2rad(sun_zenith_deg);
%     sun_zenith_cos=cos(sun_zenith_rad);
%     sun_zenith_sin=sin(sun_zenith_rad);
% %     clear sun_zenith_deg sun_zenith_rad sun_zenith_rad;
%     cos_sita=sun_zenith_cos.*cos(deg2rad(slope_data))+sun_zenith_sin.*sin(deg2rad(slope_data)).*cos(deg2rad(sun_azimuth_deg-aspect_data));
% %     clear aspect_data;
%     cos_sita_exclude_cloud=cos_sita(index_exclude_cloud_water);
% %      hist(cos_sita_exclude_cloud,100)
%     data_exclude_cloud=data_ori(index_exclude_cloud_water);
% %     clear index_exclude_cloud_water sun_zenith_deg sun_azimuth_deg;
% %     figure;plot(double(cos_sita_exclude_cloud),double(data_exclude_cloud),'r.');
%     corrcoef(double(cos_sita_exclude_cloud),double(data_exclude_cloud))
%     
%     c_fitted=polyfit(double(cos_sita_exclude_cloud),double(data_exclude_cloud),1);  
% %     clear cos_sita_exclude_cloud data_exclude_cloud; 
%     c=c_fitted(1,2)/c_fitted(1,1);
% %     clear c_fitted;
%     data_corected=double(data_ori).*(cos(deg2rad(slope_data)).*sun_zenith_cos+c)./(cos_sita+c);
% %     figure;plot(double(cos_sita_exclude_cloud),double(data_corected(index_exclude_cloud_water)),'r.');
% %     figure;plot(double(cos_sita_exclude_cloud),double(data_exclude_cloud),'r.');
% end
