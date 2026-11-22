require 'minitest/autorun'
require 'json'

# The browser loads marked and DOMPurify from esm.sh through the import map in
# index.html, while the frontend tests run against the copies npm installed.
# If the two drift apart, the tests vouch for a library the browser never runs.
class ImportMapSpec < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)

  def test_browser_loads_the_marked_version_the_frontend_tests_run_against
    assert_equal "https://esm.sh/marked@#{installed_version('marked')}", import_map['marked']
  end

  def test_browser_loads_the_dompurify_version_the_frontend_tests_run_against
    assert_equal "https://esm.sh/dompurify@#{installed_version('dompurify')}", import_map['dompurify']
  end

  private

  def import_map
    html = File.read(File.join(ROOT, 'public/index.html'))
    JSON.parse(html[%r{<script type="importmap">(.*?)</script>}m, 1])['imports']
  end

  def installed_version(package)
    lock = JSON.parse(File.read(File.join(ROOT, 'package-lock.json')))
    lock.dig('packages', "node_modules/#{package}", 'version')
  end
end
