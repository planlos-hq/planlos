package cmd

import (
	"context"
	"os"

	"charm.land/fang/v2"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:          "planlos",
	Short:        "Tooling for Planlos",
	SilenceUsage: true,
}

func Execute() {
	if err := fang.Execute(context.Background(), rootCmd); err != nil {
		os.Exit(1)
	}
}
