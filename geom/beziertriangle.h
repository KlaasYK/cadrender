#ifndef BEZIERTRIANGLE_H
#define BEZIERTRIANGLE_H

#include <geom/bezierpatch.h>

class BezierTriangle : public BezierPatch
{
public:

    // =========================================================================
    // -- Enums ----------------------------------------------------------------
    // =========================================================================

    enum ControlPoints {
        B003 = 0,
        B102,
        B201,
        B300,
        B210,
        B120,
        B030,
        B021,
        B012,
        B111,
        NUM_CONTROL_POINTS
    };

    // =========================================================================
    // -- Constructors and destructor ------------------------------------------
    // =========================================================================

public:

    BezierTriangle(const QVector<QVector4D> &controlPoints);

    virtual ~BezierTriangle();

    // =========================================================================
    // -- Other methods --------------------------------------------------------
    // =========================================================================

public:

    virtual unsigned getNumControlPoints() const override{
        return NUM_CONTROL_POINTS;
    }

    virtual const QVector<QVector4D> &getControlPoints() const override {
        return _controlPoints;
    }

    virtual Type getPatchType() const override {
        return TriPatch;
    }
};

#endif // BEZIERTRIANGLE_H
