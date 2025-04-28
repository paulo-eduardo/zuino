package main

import (
	"fmt"
	"os"

	"github.com/aws/aws-cdk-go/awscdk/v2"

	// "github.com/aws/aws-cdk-go/awscdk/v2/awssqs"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsapigateway"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsapigatewayv2"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsapigatewayv2integrations"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscodebuild"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscodedeploy"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscodepipeline"
	"github.com/aws/aws-cdk-go/awscdk/v2/awscodepipelineactions"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsec2"
	"github.com/aws/aws-cdk-go/awscdk/v2/awsiam"
	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
)

type InfrastructureStackProps struct {
	awscdk.StackProps
}

func NewInfrastructureStack(scope constructs.Construct, id string, props *InfrastructureStackProps) awscdk.Stack {
	var sprops awscdk.StackProps
	if props != nil {
		sprops = props.StackProps
	}
	stack := awscdk.NewStack(scope, &id, &sprops)

	instanceRole := awsiam.NewRole(stack, jsii.String("EC2InstanceRole"), &awsiam.RoleProps{
		AssumedBy:   awsiam.NewServicePrincipal(jsii.String("ec2.amazonaws.com"), nil),
		Description: jsii.String("Role fore EC2 instance managed by CodeDeploy and SSM"),

		ManagedPolicies: &[]awsiam.IManagedPolicy{
			awsiam.ManagedPolicy_FromAwsManagedPolicyName(jsii.String("AmazonSSMManagedInstanceCore")),
			awsiam.ManagedPolicy_FromAwsManagedPolicyName(jsii.String("AmazonS3ReadOnlyAccess")),
		},
	})

	geminiApiKeyParameterName := "/zuino/api/gemini-api-key"

	instanceRole.AddToPolicy(awsiam.NewPolicyStatement(&awsiam.PolicyStatementProps{
		Effect: awsiam.Effect_ALLOW,
		Actions: &[]*string{
			jsii.String("ssm:GetParameter"),
		},
		Resources: &[]*string{
			awscdk.Arn_Format(&awscdk.ArnComponents{
				Service:      jsii.String("ssm"),
				Region:       stack.Region(),
				Account:      stack.Account(),
				Resource:     jsii.String("parameter"),
				ResourceName: jsii.String(geminiApiKeyParameterName),
			}, stack),
		},
	}))

	vpc := awsec2.Vpc_FromLookup(stack, jsii.String("DefaultVPC"), &awsec2.VpcLookupOptions{
		IsDefault: jsii.Bool(true),
	})

	instanceSg := awsec2.NewSecurityGroup(stack, jsii.String("EC2InstanceSecurityGroup"), &awsec2.SecurityGroupProps{
		Vpc:              vpc,
		Description:      jsii.String("Allow HTTP traffic on port 3000 from anywhere"),
		AllowAllOutbound: jsii.Bool(true),
	})

	instanceSg.AddIngressRule(awsec2.Peer_AnyIpv4(),
		awsec2.Port_Tcp(jsii.Number(3000)),
		jsii.String("Allow HTTP trafic on port 3000"),
		nil,
	)

	userDataBytes, err := os.ReadFile("scripts/ec2-init.sh")
	if err != nil {
		panic("Failed to read UserData script file: scripts/ec2-init.sh\n" + err.Error())
	}

	userDataScript := string(userDataBytes)

	userData := awsec2.UserData_ForLinux(&awsec2.LinuxUserDataOptions{
		Shebang: jsii.String("#!/bin/bash"),
	})
	userData.AddCommands(jsii.String(userDataScript))

	instance := awsec2.NewInstance(stack, jsii.String("AppEC2Instance"), &awsec2.InstanceProps{
		Vpc:                      vpc,
		InstanceType:             awsec2.InstanceType_Of(awsec2.InstanceClass_T3, awsec2.InstanceSize_MICRO),
		MachineImage:             awsec2.MachineImage_LatestAmazonLinux2023(nil),
		SecurityGroup:            instanceSg,
		Role:                     instanceRole,
		UserData:                 userData,
		VpcSubnets:               &awsec2.SubnetSelection{SubnetType: awsec2.SubnetType_PUBLIC},
		AssociatePublicIpAddress: jsii.Bool(true),
	})

	awscdk.Tags_Of(instance).Add(jsii.String("App"), jsii.String("MyBackend"), &awscdk.TagProps{})

	awscdk.NewCfnOutput(stack, jsii.String("InstancePublicIpOutput"), &awscdk.CfnOutputProps{
		Value:       instance.InstancePublicIp(),
		Description: jsii.String("Public IP Address of the EC2 instance"),
	})

	corsPreflightOptions := &awsapigatewayv2.CorsPreflightOptions{
		AllowHeaders: &[]*string{jsii.String("*")},
		AllowMethods: &[]awsapigatewayv2.CorsHttpMethod{awsapigatewayv2.CorsHttpMethod_POST},
		AllowOrigins: &[]*string{jsii.String("*")},
	}

	httpApi := awsapigatewayv2.NewHttpApi(stack, jsii.String("NewHttpApi"), &awsapigatewayv2.HttpApiProps{
		ApiName:       jsii.String("ZuinoServicesApi"),
		Description:   jsii.String("HTTP API Gateway for Zuino Backend Services"),
		CorsPreflight: corsPreflightOptions,
	})

	awscdk.NewCfnOutput(stack, jsii.String("ApiGatewayUrlOutput"), &awscdk.CfnOutputProps{
		Value:       httpApi.ApiEndpoint(),
		Description: jsii.String("Endpoint URL for the HTTP API Gateway"),
	})

	instanceUrl := fmt.Sprintf("http://%s:%d", *instance.InstancePublicDnsName(), 3000)

	ec2Integration := awsapigatewayv2integrations.NewHttpUrlIntegration(
		jsii.String("EC2Integration"),
		jsii.String(instanceUrl),
		&awsapigatewayv2integrations.HttpUrlIntegrationProps{
			Method: awsapigatewayv2.HttpMethod_ANY, // Forward ANY HTTP method
		},
	)

	awsapigatewayv2.NewHttpRoute(stack, jsii.String("DefaultRoute"), &awsapigatewayv2.HttpRouteProps{
		HttpApi:     httpApi,
		RouteKey:    awsapigatewayv2.HttpRouteKey_DEFAULT(),
		Integration: ec2Integration,
	})

	apiKey := awsapigateway.NewApiKey(stack, jsii.String("AppApiKey"), &awsapigateway.ApiKeyProps{
		ApiKeyName:  jsii.String("zuino-mobile-app-key"),
		Description: jsii.String("API Key para o aplicativo mobile Zuino"),
		Enabled:     jsii.Bool(true),
	})

	usagePlan := awsapigateway.NewUsagePlan(stack, jsii.String("AppUsagePlan"), &awsapigateway.UsagePlanProps{
		Name:        jsii.String("ZuinoAppUsagePlan"),
		Description: jsii.String("Plano de uso para o aplicativo Mobile"),
	},
	// Opcional: Configurar Throttling (limite de taxa)
	// Throttle: &awsapigateway.ThrottleSettings{
	//  RateLimit: jsii.Number(10), // reqs/segundo
	//  BurstLimit: jsii.Number(5),  // capacidade de burst
	// },
	// Opcional: Configurar Quota (limite de requisições)
	// Quota: &awsapigateway.QuotaSettings{
	//  Limit:  jsii.Number(1000), // total de requisições
	//  Period: awsapigateway.Period_DAY, // período (DIA, SEMANA, MES)
	// },
	)

	usagePlan.AddApiKey(apiKey, nil)

	awscdk.NewCfnOutput(stack, jsii.String("ApiKeyIdOutput"), &awscdk.CfnOutputProps{
		Value:       apiKey.KeyId(),
		Description: jsii.String("ID da API Key gerada (obtenha o valor secreto do console/secrets manager)"),
	})

	buildProject := awscodebuild.NewPipelineProject(stack, jsii.String("AppCodeBuildProject"), &awscodebuild.PipelineProjectProps{
		ProjectName: jsii.String("ZuinoReceiptApiBuild"),
		BuildSpec:   awscodebuild.BuildSpec_FromSourceFilename(jsii.String("services/receipt-api/buildspec.yml")),
		Environment: &awscodebuild.BuildEnvironment{
			BuildImage:  awscodebuild.LinuxBuildImage_STANDARD_7_0(),
			ComputeType: awscodebuild.ComputeType_SMALL,
			Privileged:  jsii.Bool(false),
		},

		Cache: awscodebuild.Cache_Local(
			awscodebuild.LocalCacheMode_SOURCE,
			awscodebuild.LocalCacheMode_CUSTOM,
		),
	})

	codedeployApp := awscodedeploy.NewServerApplication(stack, jsii.String("CodeDeployApplication"), &awscodedeploy.ServerApplicationProps{
		ApplicationName: jsii.String("ZuinoReceiptApiService-App"),
	})

	deploymentGroup := awscodedeploy.NewServerDeploymentGroup(stack, jsii.String("CodeDeployDeploymentGroup"), &awscodedeploy.ServerDeploymentGroupProps{
		Application:         codedeployApp,
		DeploymentGroupName: jsii.String("ZuinoReceiptApiService-DG"),

		Ec2InstanceTags: awscodedeploy.NewInstanceTagSet(
			&map[string]*[]*string{
				"App": {jsii.String("MyBackend")},
			},
		),
		InstallAgent: jsii.Bool(true),

		DeploymentConfig: awscodedeploy.ServerDeploymentConfig_ONE_AT_A_TIME(),

		AutoRollback: &awscodedeploy.AutoRollbackConfig{
			FailedDeployment: jsii.Bool(true),
		},
	})

	sourceOutput := awscodepipeline.NewArtifact(jsii.String("SourceOutput"), nil)
	buildOutput := awscodepipeline.NewArtifact(jsii.String("BuildOutput"), nil)

	connectionArn := jsii.String("arn:aws:codeconnections:us-east-1:314678225910:connection/48e26a39-dd56-4de1-8539-d6dc839972a2")
	githubOwner := jsii.String("paulo-eduardo")
	githubRepo := jsii.String("zuino")
	githubBranch := jsii.String("main")

	pipeline := awscodepipeline.NewPipeline(stack, jsii.String("CiCdPipeline"), &awscodepipeline.PipelineProps{
		PipelineName:     jsii.String("ZuinoReceiptApiPipeline"),
		CrossAccountKeys: jsii.Bool(false),
	})

	// Source (Obter codigo do Github)
	pipeline.AddStage(&awscodepipeline.StageOptions{
		StageName: jsii.String("Source"),
		Actions: &[]awscodepipeline.IAction{
			awscodepipelineactions.NewCodeStarConnectionsSourceAction(&awscodepipelineactions.CodeStarConnectionsSourceActionProps{
				ActionName:    jsii.String("GitHub_Source"),
				Owner:         githubOwner,
				Repo:          githubRepo,
				Branch:        githubBranch,
				ConnectionArn: connectionArn,
				Output:        sourceOutput,
			}),
		},
	})

	// Build (Compilar e empacotar usando CodeBuild)
	pipeline.AddStage(&awscodepipeline.StageOptions{
		StageName: jsii.String("Build"),
		Actions: &[]awscodepipeline.IAction{
			awscodepipelineactions.NewCodeBuildAction(&awscodepipelineactions.CodeBuildActionProps{
				ActionName: jsii.String("CodeBuild"),
				Project:    buildProject,
				Input:      sourceOutput,
				Outputs: &[]awscodepipeline.Artifact{
					buildOutput,
				},
			}),
		},
	})

	// Deploy (Implantar na EC2 usando CodeDeploy)
	pipeline.AddStage(&awscodepipeline.StageOptions{
		StageName: jsii.String("Deploy"),
		Actions: &[]awscodepipeline.IAction{
			awscodepipelineactions.NewCodeDeployServerDeployAction(&awscodepipelineactions.CodeDeployServerDeployActionProps{
				ActionName:      jsii.String("CodeDeploy_To_EC2"),
				DeploymentGroup: deploymentGroup,
				Input:           buildOutput,
			}),
		},
	})

	return stack
}

func main() {
	defer jsii.Close()

	app := awscdk.NewApp(nil)

	NewInfrastructureStack(app, "ZuinoServicesStack", &InfrastructureStackProps{
		awscdk.StackProps{
			Env: env(),
		},
	})

	app.Synth(nil)
}

func env() *awscdk.Environment {
	account := os.Getenv("CDK_DEFAULT_ACCOUNT")
	region := os.Getenv("CDK_DEFAULT_REGION")

	if account == "" || region == "" {
		panic("Variáveis de ambiente CDK_DEFAULT_ACCOUNT e CDK_DEFAULT_REGION não definidas. " +
			"Configure seu perfil AWS ou exporte AWS_PROFILE.")
	}

	return &awscdk.Environment{
		Account: jsii.String(account),
		Region:  jsii.String(region),
	}
}
