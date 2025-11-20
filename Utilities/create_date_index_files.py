import sys
import textwrap
from datetime import datetime, timedelta
from pathlib import Path

# Top line date folder e.g. playlethalfun/2025-10-01
def create_top_line_date_file(date: str):
    html = """
    <!doctype html>
    <meta charset="utf-8">
    <title>Lethal – %s</title> 
    <script>
    // Pick up device preference
    let deviceType = localStorage.getItem('device_type');
    if (deviceType !== 'desktop' && deviceType !== 'mobile') {
        deviceType = 'mobile'; // default fallback
    }

    // Redirect
    location.replace("/" + deviceType + "/%s/"); 
    </script>
    """

    dir_path = Path(__file__).parent.parent / f"{date}"
    file_path = dir_path / "index.html"

    print(f"Writing to {dir_path}/{file_path}:")
    print(html % (date,date))

    dir_path.mkdir(parents=True, exist_ok=True)

    formatted_html = textwrap.dedent(html % (date,date))
    file_path.write_text(formatted_html)

# Desktop date folder
def create_desktop_date_file(date: str):
    html = """
    <!doctype html>
    <meta charset="utf-8">
    <title>Lethal – %s</title>
    <script>
    // Build absolute URL to the evergreen build at the site root
    const url = new URL("/desktop/", window.location.origin);
    url.searchParams.set("puzzle_date", "%s");

    // Redirect
    location.replace(url.toString());
    </script>
    """

    dir_path = Path(__file__).parent.parent / "desktop" / f"{date}"
    file_path = dir_path / "index.html"

    print(f"Writing to {dir_path}/{file_path}:")
    print(html % (date,date))

    dir_path.mkdir(parents=True, exist_ok=True)

    formatted_html = textwrap.dedent(html % (date,date))
    file_path.write_text(formatted_html)

# Mobile date folder
def create_mobile_date_folder(date: str):
    html = """
    <!doctype html>
    <meta charset="utf-8">
    <title>Lethal – %s</title>
    <script>
    // Build absolute URL to the evergreen build at the site root
    const url = new URL("/mobile/", window.location.origin);
    url.searchParams.set("puzzle_date", "%s");

    // Redirect
    location.replace(url.toString());
    </script>
    """

    dir_path = Path(__file__).parent.parent / "mobile" / f"{date}"
    file_path = dir_path / "index.html"

    print(f"Writing to {dir_path}/{file_path}:")
    print(html % (date,date))

    dir_path.mkdir(parents=True, exist_ok=True)

    formatted_html = textwrap.dedent(html % (date,date))
    file_path.write_text(formatted_html)


def dates_between(start: str, end: str):
    start_date = datetime.strptime(start, "%Y-%m-%d").date()
    end_date = datetime.strptime(end, "%Y-%m-%d").date()

    delta = (end_date - start_date).days

    return [(start_date + timedelta(days=i)).isoformat() for i in range(delta + 1)]

if __name__ == "__main__":
    
    if len(sys.argv) == 2:
        date = sys.argv[1]

        create_top_line_date_file(date)
        create_desktop_date_file(date)
        create_mobile_date_folder(date)
        
    elif len(sys.argv) == 3:
        start_date = sys.argv[1]
        end_date = sys.argv[2]

        dates = dates_between(start_date, end_date)
        
        for date in dates:
            create_top_line_date_file(date)
            create_desktop_date_file(date)
            create_mobile_date_folder(date)