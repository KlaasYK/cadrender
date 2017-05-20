#ifndef BEZIERPATCH_H
#define BEZIERPATCH_H

#include <QVector>
#include <QVector4D>

/*!
 * \brief The BezierPatch class
 *
 * Base BezierPatch class
 */
class BezierPatch
{

    // =========================================================================
    // -- Enums ----------------------------------------------------------------
    // =========================================================================

public:

    enum Type {
        TriPatch,
        QuadPatch
    };

    // =========================================================================
    // -- Constructors and destructor ------------------------------------------
    // =========================================================================

public:

    BezierPatch();

    virtual ~BezierPatch();

    // =========================================================================
    // -- Other methods --------------------------------------------------------
    // =========================================================================

public:

    virtual unsigned getNumControlPoints() const =0 ;

    virtual const QVector<QVector4D> &getControlPoints() const =0;

    virtual Type getPatchType() const =0;

    // =========================================================================
    // -- Data members ---------------------------------------------------------
    // =========================================================================

protected:

    QVector<QVector4D> _controlPoints;

};

#endif // BEZIERPATCH_H
