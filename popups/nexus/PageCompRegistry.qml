pragma Singleton

import QtQuick
import qs.popups.nexus
import qs.popups.nexus.pages
import qs.popups.nexus.pages.wallpapers

QtObject {
    readonly property list<Component> pageComps: [

        Component {
            StackPage {
                Component {
                    AppearancePage {}
                }
                Component {
                    WallpaperSelectPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    ThemeTargetsPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    DisplayPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    PanelsPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    AudioPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    NetworkPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    BluetoothPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    ServicesPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    NotificationsPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    KeybindsPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    LanguageAndRegionPage {}
                }
            }
        },

        Component {
            StackPage {
                Component {
                    AboutPage {}
                }
            }
        }
    ]

    readonly property Component placeholderComp: Component {
        PlaceholderPage {}
    }
}
