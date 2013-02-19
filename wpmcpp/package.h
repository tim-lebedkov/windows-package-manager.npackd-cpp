#ifndef PACKAGE_H
#define PACKAGE_H

#include <QString>
#include <QStringList>
#include <QDomElement>

/**
 * A package declaration.
 */
class Package
{
public:
    /** name of the package like "org.buggysoft.BuggyEditor" */
    QString name;

    /** short program title (1 line) like "Gimp" */
    QString title;

    /** web page associated with this piece of software. May be empty. */
    QString url;

    /** icon URL or "" */
    QString icon;

    /** description. May contain multiple lines and paragraphs. */
    QString description;

    /** name of the license like "org.gnu.GPLv3" or "" if unknown */
    QString license;

    Package(const QString& name, const QString& title);

    /**
     * Checks whether the specified value is a valid package name.
     *
     * @param a string that should be checked
     * @return true if name is a valid package name
     */
    static bool isValidName(QString& name);

    /**
     * Save the contents as XML.
     *
     * @param e <package>
     */
    void saveTo(QDomElement& e) const;
};

#endif // PACKAGE_H
