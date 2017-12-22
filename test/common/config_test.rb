# Copyright 2017 OpenCensus Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "test_helper"

describe OpenCensus::Common::Config do
  let(:config) { OpenCensus::Common::Config.new }

  describe "an empty config" do
    it "returns no options or subconfigs" do
      config.options!.must_equal []
      config.subconfigs!.must_equal []
      config.option?(:option1).must_equal false
      config.subconfig?(:option1).must_equal false
    end

    it "generates empty inspection" do
      config.to_h!.must_equal({})
      config.to_s!.must_equal "<Config>"
    end
  end

  describe "a nonexistent option" do
    let(:config) { OpenCensus::Common::Config.new }

    it "cannot be set via []" do
      ->{
        config[:option1] = "hello"
      }.must_raise "Key :option1 does not exist"
    end

    it "cannot be read via []" do
      ->{
        config[:option1]
      }.must_raise "Key :option1 does not exist"
    end

    it "cannot be set via named method" do
      ->{
        config.option1 = "hello"
      }.must_raise "Key :option1 does not exist"
    end

    it "cannot be read via named method" do
      ->{
        config.option1
      }.must_raise "Key :option1 does not exist"
    end
  end

  describe "a default option" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1
      end
    }

    it "appears in the options list" do
      config.options!.must_equal [:option1]
      config.option?(:option1).must_equal true
    end

    it "won't appear in the subconfigs list" do
      config.subconfigs!.wont_include :option1
      config.subconfig?(:option1).must_equal false
    end

    it "can be set and read via [] using a symbol key" do
      config[:option1] = "hello"
      config[:option1].must_equal "hello"
    end

    it "can be set and read via [] using a string key" do
      config["option1"] = "hello"
      config["option1"].must_equal "hello"
    end

    it "can be set and read via named methods" do
      config.option1 = "hello"
      config.option1.must_equal "hello"
    end

    it "defaults to nil" do
      config[:option1].must_be_nil
      config["option1"].must_be_nil
      config.option1.must_be_nil
    end
  end

  describe "a default integer option" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, 10
      end
    }

    it "has the expected default" do
      config[:option1].must_equal 10
      config["option1"].must_equal 10
      config.option1.must_equal 10
    end

    it "can be set to another integer" do
      config.option1 = 20
      config.option1.must_equal 20
    end

    it "cannot be set to a string" do
      ->{
        config.option1 = "hello"
      }.must_raise "Invalid value \"hello\" for key :option1"
    end

    it "cannot be set to nil" do
      ->{
        config.option1 = nil
      }.must_raise "Invalid value nil for key :option1"
    end
  end

  describe "a default boolean option" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, false
      end
    }

    it "has the expected default" do
      config[:option1].must_equal false
      config["option1"].must_equal false
      config.option1.must_equal false
    end

    it "can be set to a boolean" do
      config.option1 = true
      config.option1.must_equal true
      config.option1 = false
      config.option1.must_equal false
    end

    it "cannot be set to a string" do
      ->{
        config.option1 = "hello"
      }.must_raise "Invalid value \"hello\" for key :option1"
    end

    it "cannot be set to nil" do
      ->{
        config.option1 = nil
      }.must_raise "Invalid value nil for key :option1"
    end
  end

  describe "a string option with a class matcher" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, "hello", match: [String, Symbol]
      end
    }

    it "has the expected default" do
      config[:option1].must_equal "hello"
      config["option1"].must_equal "hello"
      config.option1.must_equal "hello"
    end

    it "can be set to a symbol" do
      config.option1 = :hello
      config.option1.must_equal :hello
    end

    it "can be set to a string" do
      config.option1 = "bye"
      config.option1.must_equal "bye"
    end

    it "cannot be set to an integer" do
      ->{
        config.option1 = 123
      }.must_raise "Invalid value 123 for key :option1"
    end

    it "cannot be set to nil" do
      ->{
        config.option1 = nil
      }.must_raise "Invalid value nil for key :option1"
    end
  end

  describe "a string option with a regex matcher allowing nil" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, "hi", match: %r{^[a-z]+$}, allow_nil: true
      end
    }

    it "has the expected default" do
      config[:option1].must_equal "hi"
      config["option1"].must_equal "hi"
      config.option1.must_equal "hi"
    end

    it "can be set to a matching string" do
      config.option1 = "bye"
      config.option1.must_equal "bye"
    end

    it "cannot be set to a non-matching string" do
      ->{
        config.option1 = "BYE"
      }.must_raise "Invalid value \"BYE\" for key :option1"
    end

    it "cannot be set to an integer" do
      ->{
        config.option1 = 123
      }.must_raise "Invalid value 123 for key :option1"
    end

    it "can be set to nil" do
      config.option1 = nil
      config.option1.must_be_nil
    end
  end

  describe "an enum option" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, :one, enum: [:one, :two, :three]
      end
    }

    it "has the expected default" do
      config[:option1].must_equal :one
      config["option1"].must_equal :one
      config.option1.must_equal :one
    end

    it "can be set to a legal value" do
      config.option1 = :two
      config.option1.must_equal :two
    end

    it "cannot be set to an illegal value" do
      ->{
        config.option1 = :four
      }.must_raise "Invalid value :four for key :option1"
    end

    it "cannot be set to nil" do
      ->{
        config.option1 = nil
      }.must_raise "Invalid value nil for key :option1"
    end
  end

  describe "an enum option allowing nil" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, :hi, enum: [:hi, :bye], allow_nil: true
      end
    }

    it "has the expected default" do
      config[:option1].must_equal :hi
      config["option1"].must_equal :hi
      config.option1.must_equal :hi
    end

    it "can be set to a legal value" do
      config.option1 = :bye
      config.option1.must_equal :bye
    end

    it "cannot be set to an illegal value" do
      ->{
        config.option1 = :four
      }.must_raise "Invalid value :four for key :option1"
    end

    it "can be set to nil" do
      config.option1 = nil
      config.option1.must_be_nil
    end
  end

  describe "an option with a custom validator" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1, 0 do |val|
          val % 2 == 0
        end
      end
    }

    it "has the expected default" do
      config[:option1].must_equal 0
      config["option1"].must_equal 0
      config.option1.must_equal 0
    end

    it "can be set to a legal value" do
      config.option1 = 2
      config.option1.must_equal 2
    end

    it "cannot be set to an illegal value" do
      ->{
        config.option1 = 3
      }.must_raise "Invalid value 3 for key :option1"
    end
  end

  describe "a subconfig" do
    let(:config) {
      OpenCensus::Common::Config.new do |config|
        config.add_option! :option1
        config.add_config! :sub do |config2|
          config2.add_option! :option2
        end
      end
    }

    it "provides access to its suboptions via []" do
      config[:sub].option2 = "hi"
      config["sub"].option2.must_equal "hi"
    end

    it "provides access to its suboptions via named method" do
      config.sub.option2 = "hi"
      config.sub.option2.must_equal "hi"
    end

    it "cannot be set via []" do
      ->{
        config[:sub1] = "hi"
      }.must_raise "Key :sub is a subconfig"
    end

    it "cannot be set via named method" do
      ->{
        config.sub1 = "hi"
      }.must_raise "Key :sub is a subconfig"
    end
  end

end
