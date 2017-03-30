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
func getScalingJobConfig() ScalingJobConfig {
	sj := ScalingJobConfig{}

	jobFQN := os.Getenv("TARGET_JOB")
	if jobFQN == "" {
		fmt.Println("TARGET_JOB not set in environment")
		os.Exit(1)
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
		panic(err)
	}
	sj.rescaler = rescaler

	return sj
}

func getThresholdsRescalerConfig() *rescalers.ThresholdsRescalerConfig {
	config := &rescalers.ThresholdsRescalerConfig{}

	cpuRoof := os.Getenv("CPU_ROOF")
	if cpuRoof == "" {
		fmt.Println("CPU_ROOF not set. Defaulting cpu roof to 80%")
		config.Upper = 80.0
	} else {
		config.Upper, _ = strconv.ParseFloat(cpuRoof, 64)
	}

	cpuFloor := os.Getenv("CPU_FLOOR")
	if cpuFloor == "" {
		fmt.Println("CPU_FLOOR not set. Defaulting cpu floor to 20%")
		config.Lower = 20.0
	} else {
		config.Lower, _ = strconv.ParseFloat(cpuFloor, 64)
	}

	instanceCounter := os.Getenv("INSTANCE_COUNTER")
	if instanceCounter == "" {
		fmt.Println("INSTANCE_COUNTER not set. Defaulting instance counter to 1")
		config.Size = 1
	} else {
		config.Size, _ = strconv.Atoi(instanceCounter)
	}

	inverted := os.Getenv("INVERTED")
	if inverted == "" {
		fmt.Println("INVERTED not set. Defaulting to false")
		config.Inverted = false
	} else {
		config.Inverted = true
	}

	return config
}

func getFeedbackRescalerConfig() *rescalers.FeedbackRescalerConfig {
	config := &rescalers.FeedbackRescalerConfig{}

	setpoint := os.Getenv("SETPOINT")
	if setpoint == "" {
		fmt.Println("SETPOINT not set. Defaulting setpoint to 50%")
		config.Setpoint = 50.0
	} else {
		config.Setpoint, _ = strconv.ParseFloat(setpoint, 64)
	}

	kp := os.Getenv("KP")
	if kp == "" {
		fmt.Println("KP not set. Defaulting KP to 4")
		config.KP = 4.0
	} else {
		config.KP, _ = strconv.ParseFloat(kp, 64)
	}

	ki := os.Getenv("KI")
	if ki == "" {
		fmt.Println("KI not set. Defaulting KI to 0")
		config.KI = 0.0
	} else {
		config.KI, _ = strconv.ParseFloat(ki, 64)
	}

	kd := os.Getenv("KD")
	if kd == "" {
		fmt.Println("KD not set. Defaulting KD to 0")
		config.KD = 0.0
	} else {
		config.KD, _ = strconv.ParseFloat(kd, 64)
	}

	inverted := os.Getenv("INVERTED")
	if inverted == "" {
		fmt.Println("INVERTED not set. Defaulting to false")
		config.Inverted = false
	} else {
		config.Inverted = true
	}

	return config
}

func makeRescaler(rescalerType string) (rescalers.Rescaler, error) {
	if rescalerType == Thresholds {
		return rescalers.NewThresholdsRescaler(getThresholdsRescalerConfig()), nil
	}
	if rescalerType == Feedback {
		return rescalers.NewFeedbackRescaler(getFeedbackRescalerConfig()), nil
	}
	return nil, fmt.Errorf("Unknown rescaler type %s", rescalerType)
}

func main() {
	// The DefaultJobScaler / the default scaling algorithm to be used
	// for making scaling decisions.
	config := getScalingJobConfig()
	printScalingJobConfig(&config)
	jobScaler := NewJobScaler()
	jobScaler.EnableAutoScale(config)

	for {
		select {
		case <-jobScaler.Inactive():
			fmt.Println("Job Scaler Down. Shutting down...")
			os.Exit(1)
		}
	}
}
