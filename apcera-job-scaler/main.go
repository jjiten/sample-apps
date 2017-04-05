// Copyright 2016 Apcera Inc. All rights reserved.

package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/apcera/sample-apps/apcera-job-scaler/rescalers"
)

const (
	Thresholds = "THRESHOLDS"
	Feedback   = "FEEDBACK"
)

func printScalingJobConfig(config *ScalingJobConfig) {
	fmt.Println("Scaling Job Config set...")
	fmt.Println("FQN: ", config.jobFQN)
	fmt.Println("Scaling Frequency: ", config.scalingFrequency)
	fmt.Println("Minimum Instance limit: ", config.minInstances)
	fmt.Println("Maximum Instance limit: ", config.maxInstances)
}

// getScalingJobConfig constructs the configurations of the scaling job and
// its associated scaling triggers from environment variables if set, or else
// populates with default values
func getScalingJobConfig() (*ScalingJobConfig, error) {
	sj := &ScalingJobConfig{}

	jobFQN := os.Getenv("TARGET_JOB")
	if jobFQN == "" {
		return nil, fmt.Errorf("TARGET_JOB not set")
	}
	sj.jobFQN = jobFQN

	scalingFrequency := os.Getenv("SCALING_FREQ")
	if scalingFrequency == "" {
		fmt.Println("SCALING_FREQ not set. Defaulting scaling frequency to 1 minute")
		sj.scalingFrequency = 1 * time.Minute
	} else {
		sf, _ := strconv.Atoi(scalingFrequency)
		sj.scalingFrequency = time.Duration(sf) * time.Second
	}

	rescalerType := os.Getenv("RESCALER")
	if rescalerType == "" {
		fmt.Println("RESCALER not set. Defaulting rescaler to THRESHOLDS")
		rescalerType = Thresholds
	}
	if rescalerType != Thresholds || rescalerType != Feedback {
		fmt.Println("RESCALER unknown. Defaulting rescaler to THRESHOLDS")
		rescalerType = Thresholds
	}

	maxInstances := os.Getenv("MAX_INSTANCES")
	if maxInstances == "" {
		fmt.Println("MAX_INSTANCES not set. Defaulting max instances to 99")
		sj.maxInstances = 99
	} else {
		sj.maxInstances, _ = strconv.Atoi(maxInstances)
	}

	minInstances := os.Getenv("MIN_INSTANCES")
	if minInstances == "" {
		fmt.Println("MIN_INSTANCES not set. Defaulting min instances to 1")
		sj.minInstances = 1
	} else {
		sj.minInstances, _ = strconv.Atoi(minInstances)
	}

	rescaler, err := makeRescaler(rescalerType)
	if err != nil {
		return nil, fmt.Errorf("failed to make rescaler: %s", err)
	}
	sj.rescaler = rescaler

	return sj, nil
}

func getThresholdsRescalerConfig() (*rescalers.ThresholdsRescalerConfig, error) {
	var err error
	config := &rescalers.ThresholdsRescalerConfig{}

	cpuRoof := os.Getenv("CPU_ROOF")
	if cpuRoof == "" {
		fmt.Println("CPU_ROOF not set. Defaulting cpu roof to 80%")
		config.Upper = 80.0
	} else {
		config.Upper, err = strconv.ParseFloat(cpuRoof, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid CPU_ROOF: %s", err)
		}
	}

	cpuFloor := os.Getenv("CPU_FLOOR")
	if cpuFloor == "" {
		fmt.Println("CPU_FLOOR not set. Defaulting cpu floor to 20%")
		config.Lower = 20.0
	} else {
		config.Lower, err = strconv.ParseFloat(cpuFloor, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid CPU_FLOOR: %s", err)
		}
	}

	instanceCounter := os.Getenv("INSTANCE_COUNTER")
	if instanceCounter == "" {
		fmt.Println("INSTANCE_COUNTER not set. Defaulting instance counter to 1")
		config.Size = 1
	} else {
		config.Size, err = strconv.Atoi(instanceCounter)
	}

	inverted := os.Getenv("INVERTED")
	if inverted == "" {
		fmt.Println("INVERTED not set. Defaulting to false")
		config.Inverted = false
	} else {
		config.Inverted = true
	}

	return config, nil
}

func getFeedbackRescalerConfig() (*rescalers.FeedbackRescalerConfig, error) {
	var err error
	config := &rescalers.FeedbackRescalerConfig{}

	setpoint := os.Getenv("SETPOINT")
	if setpoint == "" {
		fmt.Println("SETPOINT not set. Defaulting setpoint to 50%")
		config.Setpoint = 50.0
	} else {
		config.Setpoint, err = strconv.ParseFloat(setpoint, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid SETPOINT: %s", err)
		}
	}

	kp := os.Getenv("KP")
	if kp == "" {
		fmt.Println("KP not set. Defaulting KP to 4")
		config.KP = 4.0
	} else {
		config.KP, err = strconv.ParseFloat(kp, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid KP: %s", err)
		}
	}

	ki := os.Getenv("KI")
	if ki == "" {
		fmt.Println("KI not set. Defaulting KI to 0")
		config.KI = 0.0
	} else {
		config.KI, err = strconv.ParseFloat(ki, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid KI: %s", err)
		}
	}

	kd := os.Getenv("KD")
	if kd == "" {
		fmt.Println("KD not set. Defaulting KD to 0")
		config.KD = 0.0
	} else {
		config.KD, err = strconv.ParseFloat(kd, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid KD: %s", err)
		}
	}

	inverted := os.Getenv("INVERTED")
	if inverted == "" {
		fmt.Println("INVERTED not set. Defaulting to false")
		config.Inverted = false
	} else {
		config.Inverted = true
	}

	return config, nil
}

func makeRescaler(rescalerType string) (rescalers.Rescaler, error) {
	if rescalerType == Thresholds {
		config, err := getThresholdsRescalerConfig()
		if err != nil {
			return nil, fmt.Errorf("invalid threshold rescaler configuration: %s", err)
		}
		return rescalers.NewThresholdsRescaler(config), nil
	}
	if rescalerType == Feedback {
		config, err := getFeedbackRescalerConfig()
		if err != nil {
			return nil, fmt.Errorf("invalid feedback rescaler configuration: %s", err)
		}
		return rescalers.NewFeedbackRescaler(config), nil
	}
	return nil, fmt.Errorf("unknown rescaler type %s", rescalerType)
}

func main() {
	// The DefaultJobScaler / the default scaling algorithm to be used
	// for making scaling decisions.
	config, err := getScalingJobConfig()
	if err != nil {
		fmt.Println("Failed to configure scaler")
		os.Exit(1)
	}
	printScalingJobConfig(config)
	jobScaler := NewJobScaler()
	jobScaler.EnableAutoScale(*config)

	for {
		select {
		case <-jobScaler.Inactive():
			fmt.Println("Job Scaler Down. Shutting down...")
			os.Exit(1)
		}
	}
}
