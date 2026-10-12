pragma Singleton

import QtQuick
import qs.popups.nexus
import qs.popups.nexus.pages
import qs.popups.nexus.pages.wallpapers

/**
 * The component behind each PageRegistry entry, at the same index.
 *
 * A section is wrapped in a StackPage so it can push detail views; the index a
 * sub-page is opened with is its position in that section's page list, which is
 * why the ordering inside each StackPage is part of the contract.
 */
QtObject {
    readonly property list<Component> pageComps: [
        // 0 - Appearance
        // Sub-pages: 1 wallpaper grid, 2 one wallpaper category.
        Component {
            StackPage {
                Component {
                    AppearancePage {}
                }
                Component {
                    WallpaperSelectPage {}
                }
                Component {
                    WallpaperCategoryPage {}
                }
            }
        },

        // 1 - Display
        Component {
            StackPage {
                Component {
                    DisplayPage {}
                }
            }
        },

        // 2 - Panels
        Component {
            StackPage {
                Component {
                    PanelsPage {}
                }
            }
        },

        // 3 - Audio
        Component {
            StackPage {
                Component {
                    AudioPage {}
                }
            }
        },

        // 4 - Network
        Component {
            StackPage {
                Component {
                    NetworkPage {}
                }
            }
        },

        // 5 - Bluetooth
        Component {
            StackPage {
                Component {
                    BluetoothPage {}
                }
            }
        },

        // 6 - Services
        Component {
            StackPage {
                Component {
                    ServicesPage {}
                }
            }
        },

        // 7 - Language & region
        Component {
            StackPage {
                Component {
                    LanguageAndRegionPage {}
                }
            }
        },

        // 8 - About
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
