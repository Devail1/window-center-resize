import './About.css';

function About() {
  return (
    <div className="about">
      <details>
        <summary>Streamlined Window Management (Read more)</summary>
        <div className="read-more-content">
          <p>
            Power users and multitaskers, maximize focus with Window Center &
            Resizer.
          </p>
          <ul>
            <li>
              <p>
                <strong>Customizable Keyboard Shortcuts:</strong> Control window
                actions efficiently for an uninterrupted workflow.
              </p>
            </li>
            <li>
              <p>
                <strong>Predefined Window Layouts:</strong> Optimize your
                workspace with pre-defined dimensions, ideal for developers,
                designers, and data analysts.
              </p>
            </li>
          </ul>
          <p>
            <strong>Free, open-source, and ad-free!</strong> (Details & updates
            on GitHub:
            <a
              target="_blank"
              rel="noopener noreferrer"
              href="https://github.com/devail1/window-center-resize"
            >
              repository
            </a>
            )
          </p>
          <p>
            <strong>Compatibility:</strong> .NET Framework 4.5, Windows 7, 8, 10
          </p>
        </div>
      </details>
    </div>
  );
}

export default About;
