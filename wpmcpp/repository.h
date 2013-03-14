#ifndef REPOSITORY_H
#define REPOSITORY_H

#include <windows.h>

#include "qfile.h"
#include "qlist.h"
#include "qurl.h"
#include "qtemporaryfile.h"
#include "qdom.h"
#include <QMutex>
#include <QMultiMap>

#include "package.h"
#include "packageversion.h"
#include "license.h"
#include "windowsregistry.h"
#include "abstractrepository.h"

/**
 * A repository is a list of packages and package versions.
 */
class Repository: public AbstractRepository
{
private:
    static Repository def;

    static Package* createPackage(QDomElement* e, QString* err);
    static License* createLicense(QDomElement* e);
    static PackageVersion* createPackageVersion(QDomElement* e,
            QString* err);

    void loadOne(QUrl* url, Job* job, bool useCache=true);

    void addWindowsPackage();

    /**
     * Finds all package versions.
     *
     * @param package full package name
     * @return the list of package versions (the objects should not
     *     be freed) sorted by the version number. The first returned object
     *     has the highest version number.
     */
    QList<PackageVersion*> getPackageVersions(const QString& package) const;

    /**
     * Find the newest installable package version.
     *
     * @param package name of the package like "org.server.Word"
     * @return found package version or 0
     */
    PackageVersion* findNewestInstallablePackageVersion(const QString& package);

    /**
     * Searches for a license by name.
     *
     * @param name name of the license like "org.gnu.GPLv3"
     * @return found license or 0
     */
    License* findLicense(const QString& name);

    /**
     * Searches for a package by name.
     *
     * @param name name of the package like "org.server.Word"
     * @return found package or 0
     */
    Package* findPackage(const QString& name);

    /**
     * Find the newest available package version.
     *
     * @param package name of the package like "org.server.Word"
     * @param version package version
     * @return found package version or 0
     */
    PackageVersion* findPackageVersion(const QString& package,
            const Version& version);
public:
    /** full package name -> all defined package versions */
    QMultiMap<QString, PackageVersion*> package2versions;

    /**
     * @brief any operation (reading or writing) on repositories, packages,
     *     package versions, licenses etc. should be done under this lock
     */
    static QMutex mutex;

    /**
     * Checks the directories of packages in the uninstall operations in the
     * given list for locked files.
     *
     * @return error message if a file or a directory is locked and cannot be
     *     uninstalled
     */
    static QString checkLockedFilesForUninstall(
            const QList<InstallOperation*> &install);

    /**
     * Loads the content from the URLs. None of the packages has the information
     * about installation path after this method was called.
     *
     * @param job job for this method
     * @param useCache true = cache will be used
     */
    void load(Job* job, bool useCache=true);

    /**
     * Package versions. All version numbers should be normalized.
     */
    QList<PackageVersion*> packageVersions;

    /**
     * Packages.
     */
    QList<Package*> packages;

    /**
     * Licenses.
     */
    QList<License*> licenses;

    /**
     * Creates an empty repository.
     */
    Repository();

    virtual ~Repository();

    /**
     * Loads one repository from an XML document.
     *
     * @param doc repository
     * @param job Job
     */
    void loadOne(QDomDocument* doc, Job* job);

    /**
     * Loads one repository from a file.
     *
     * @param filename repository file name
     * @param job Job
     */
    void loadOne(const QString& filename, Job* job);

    Package* findPackage_(const QString& name);

    /**
     * Writes this repository to an XML file.
     *
     * @param filename output file name
     * @return error message or ""
     */
    QString writeTo(const QString& filename) const;

    QList<PackageVersion*> getPackageVersions_(const QString& package,
            QString* err) const;

    QString savePackage(Package* p);

    QString savePackageVersion(PackageVersion* p);

    PackageVersion* findPackageVersionByMSIGUID_(
            const QString& guid) const;

    PackageVersion* findPackageVersion_(const QString& package,
            const Version& version);

    License* findLicense_(const QString& name);

    QString clear();

    QList<Package*> findPackagesByShortName(const QString& name);
};

#endif // REPOSITORY_H
