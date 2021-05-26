function actor = actor()
% input path layers (2 by 1 input and a 1 by 1 output)
statePath = [
    featureInputLayer(numObs,'Normalization','none','Name','observation')
    fullyConnectedLayer(192, 'Name','commonFC1')
    reluLayer('Name','CommonRelu1')
    fullyConnectedLayer(256, 'Name','commonFC3')
    reluLayer('Name','CommonRelu3')
    fullyConnectedLayer(256, 'Name','commonFC4')
    reluLayer('Name','CommonRelu4')
    fullyConnectedLayer(192, 'Name','commonFC2')
    reluLayer('Name','CommonRelu2')
    ];

meanCommonPath = [
    fullyConnectedLayer(192,'Name','MeanFC1')
    reluLayer('Name','MeanRelu1')
    fullyConnectedLayer(256,'Name','MeanFC2')
    reluLayer('Name','MeanRelu2')
    fullyConnectedLayer(192,'Name','MeanFC3')
    reluLayer('Name','MeanRelu3')
    fullyConnectedLayer(numAct,'Name','Mean')
    ];
meanTanh1Path = [
    scalingLayer('Name','meanScaling1','Bias',1.5)
    tanhLayer('Name','meantanh1')
    scalingLayer('Name','meantanh1scaling','Scale',(thrust/2),'Bias', (thrust/2))
    ];
meanTanh2Path = [
    scalingLayer('Name','meanScaling2','Bias',-1.5)
    tanhLayer('Name','meantanh2')
    scalingLayer('Name','meantanh2scaling','Scale',7.5-(thrust/2),'Bias', 7.5-(thrust/2))
    ];
add = additionLayer(2,'Name','add_1');

stdPath = [
    fullyConnectedLayer(192,'Name','StdFC1')
    reluLayer('Name','StdRelu1')
    fullyConnectedLayer(256,'Name','StdFC2')
    reluLayer('Name','StdRelu2')
    fullyConnectedLayer(192,'Name','StdFC3')
    reluLayer('Name','StdRelu3')
    fullyConnectedLayer(numAct,'Name','StdFC4')
    sigmoidLayer('Name','StdSig')
    scalingLayer('Name','ActorScaling','Scale',thrust*0.1)
    ];

concatPath = concatenationLayer(1,2,'Name','GaussianParameters');

actorNetwork = layerGraph(statePath);
actorNetwork = addLayers(actorNetwork,meanCommonPath);
actorNetwork = addLayers(actorNetwork,meanTanh1Path);
actorNetwork = addLayers(actorNetwork,meanTanh2Path);
actorNetwork = addLayers(actorNetwork,add);
actorNetwork = addLayers(actorNetwork,stdPath);
actorNetwork = addLayers(actorNetwork,concatPath);
actorNetwork = connectLayers(actorNetwork,'CommonRelu2','MeanFC1/in');
actorNetwork = connectLayers(actorNetwork, 'Mean', 'meanScaling1/in');
actorNetwork = connectLayers(actorNetwork, 'Mean', 'meanScaling2/in');
actorNetwork = connectLayers(actorNetwork,'meantanh1scaling','add_1/in1');
actorNetwork = connectLayers(actorNetwork,'meantanh2scaling','add_1/in2');
actorNetwork = connectLayers(actorNetwork,'CommonRelu2','StdFC1/in');
actorNetwork = connectLayers(actorNetwork,'add_1','GaussianParameters/in1');
actorNetwork = connectLayers(actorNetwork,'ActorScaling','GaussianParameters/in2');

actorOptions = rlRepresentationOptions('Optimizer','adam','LearnRate',2e-4,...
                                 'GradientThreshold',1);
if gpuDeviceCount("available")
    actorOpts.UseDevice = 'gpu';
end

actor = rlStochasticActorRepresentation(actorNetwork,obsInfo,actInfo,actorOptions,...
    'Observation',{'observation'});

end