require "./spec_helper"
require "colorize"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`

    `crystal src/cnf-conformance.cr samples_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr configuration_file_setup`

    # `crystal src/cnf-conformance.cr setup`
    # $?.success?.should be_true
  end

  it "'install_script_helm' should fail if install script does not have helm" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # `crystal src/cnf-conformance.cr cleanup`
    # $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_source_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr install_script_helm`
    #puts response_s
    $?.success?.should be_true
    (/FAILURE: Helm not found in supplied install script/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr sample_coredns_source_cleanup`
  end

  it "'helm_chart_valid' should pass on a good helm chart" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    # `crystal src/cnf-conformance.cr cleanup`
    # $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_chart_valid`
    puts response_s
    $?.success?.should be_true
    (/Lint Passed/ =~ response_s).should_not be_nil
  end

  it "'helm_chart_valid' should fail on a bad helm chart" do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr sample_coredns_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr bad_helm_cnf_setup`
    $?.success?.should be_true
    response_s = `crystal src/cnf-conformance.cr helm_chart_valid`
    puts response_s
    $?.success?.should be_true
    (/Lint Failed/ =~ response_s).should_not be_nil
    `crystal src/cnf-conformance.cr bad_helm_cnf_cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr sample_coredns_setup`
    $?.success?.should be_true
  end
end
