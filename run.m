close all; 
clear;
clc;
warning off;

addpath(genpath('ClusteringMeasure'));
addpath(genpath('FormulationKernels'));
addpath(genpath('function'));

ResSavePath = 'Res/';
MaxResSavePath = 'maxRes/';

if(~exist(ResSavePath,'file'))
    mkdir(ResSavePath);
    addpath(genpath(ResSavePath));
end

if(~exist(MaxResSavePath,'file'))
    mkdir(MaxResSavePath);
    addpath(genpath(MaxResSavePath));
end

dataPath='./Datasets_MVC/';
datasetName = {'MSRC_v1'};

for dataIndex = 1 : length(datasetName) - (length(datasetName) - 1)
    dataName = [dataPath datasetName{dataIndex} '.mat'];
    load(dataName, 'fea', 'gt');
    
    ResBest = zeros(1, 8);
    ResStd = zeros(1, 8);
    
    % Data Preparation
    tic;
    num_cluster = max(gt);
    [KH, HH] = preprocess(fea, num_cluster);
    time1 = toc;
    
    % parameters setting
    
    r1 = -15: 2: 15;
    r2 = -15: 2: 15;
    

    acc = zeros(length(r1), length(r2));
    nmi = zeros(length(r1), length(r2));
    purity = zeros(length(r1), length(r2));
    idx = 1;
    for r1Index = 1:length(r1)
        r1Temp = r1(r1Index);
        for r2Index = 1:length(r2)
            r2Temp = r2(r2Index);
            tic;
            % Main algorithm
            fprintf('Please wait a few minutes\n');
            disp(['Dataset: ', datasetName{dataIndex}, ...
                ', --r1--: ', num2str(r1Temp), ', --r2--: ', num2str(r2Temp)]);
            
            [F, S, mu, gamma, obj] = SLgPA(KH, HH, num_cluster, 2^r1Temp, 2^r2Temp);
            
            time2 = toc;
            
            tic;
            [res] = my_nmi_acc(real(F), gt, num_cluster);
            time3 = toc;
            
            Runtime(idx) = time1 + time2 + time3/20;
            disp(['runtime: ', num2str(Runtime(idx))]);
            idx = idx + 1;
            tempResBest(1, :) = res(1, :);
            tempResStd(1, :) = res(2, :);
            
            acc(r1Index, r2Index) = tempResBest(1, 7);
            nmi(r1Index, r2Index) = tempResBest(1, 4);
            purity(r1Index, r2Index) = tempResBest(1, 8);
            
            resFile = [ResSavePath datasetName{dataIndex}, '-ACC=', num2str(tempResBest(1, 7)), ...
                '-r1=', num2str(r1Temp), '-r2=', num2str(r2Temp), '.mat'];
            save(resFile, 'tempResBest', 'tempResStd');
            
            for tempIndex = 1:8
                if tempResBest(1, tempIndex) > ResBest(1, tempIndex)
                    new_F = F;
                    new_S = S;
                    new_mu = mu;
                    new_gamma = gamma;
                    new_obj = obj;
                    ResBest(1, tempIndex) = tempResBest(1, tempIndex);
                    ResStd(1, tempIndex) = tempResStd(1, tempIndex);
                end
            end
        end
    end
    aRuntime = mean(Runtime);
    resFile2 = [MaxResSavePath datasetName{dataIndex}, '-ACC=', num2str(ResBest(1, 7)), '.mat'];
    save(resFile2, 'ResBest', 'ResStd');
    resFile2 = [MaxResSavePath datasetName{dataIndex}, '.mat'];
    save(resFile2, 'ResBest', 'ResStd', 'acc', 'nmi', 'purity', 'aRuntime',...
        'new_F', 'new_S', 'new_mu', 'new_gamma', 'new_obj', 'gt');
    
    clear num_cluster
end

