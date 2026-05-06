# frozen_string_literal: true

require_relative "test_helper"

class ExercismRbUiTest < ExercismRbTestCase
  def test_color_is_disabled_for_non_tty_by_default
    out = StringIO.new

    with_color_env do
      Exercism::Rb::UI.new(out: out).success("Saved")
    end

    refute_includes out.string, "\e["
    assert_equal "Saved\n", out.string
  end

  def test_xrb_color_always_forces_color
    out = StringIO.new

    with_color_env("XRB_COLOR" => "always") do
      Exercism::Rb::UI.new(out: out).success("Saved")
    end

    assert_includes out.string, "\e[32m"
    assert_includes out.string, "Saved"
  end

  def test_warning_and_error_keep_color_on_stderr
    err = StringIO.new

    with_color_env("XRB_COLOR" => "always") do
      ui = Exercism::Rb::UI.new(err: err)
      ui.warn("Careful")
      ui.error("Failed")
    end

    assert_includes err.string, "\e[33mCareful\e[0m"
    assert_includes err.string, "\e[31mFailed\e[0m"
  end

  def test_xrb_color_never_disables_color_even_when_forced
    out = StringIO.new

    with_color_env("XRB_COLOR" => "never", "CLICOLOR_FORCE" => "1") do
      Exercism::Rb::UI.new(out: out).success("Saved")
    end

    refute_includes out.string, "\e["
  end

  def test_no_color_disables_auto_color
    out = StringIO.new

    with_color_env("NO_COLOR" => "1", "CLICOLOR_FORCE" => "1") do
      Exercism::Rb::UI.new(out: out).success("Saved")
    end

    refute_includes out.string, "\e["
  end

  private

  def with_color_env(values = {})
    with_env({
      "XRB_COLOR" => nil,
      "NO_COLOR" => nil,
      "CLICOLOR" => nil,
      "CLICOLOR_FORCE" => nil
    }.merge(values)) do
      yield
    end
  end
end
